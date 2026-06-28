/*
 * Copyright (c) 2024 Beijing HuaQingYuanJian Education Technology Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "soc_osal.h"
#include "app_init.h"
#include "cmsis_os2.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "MQTTClientPersistence.h"
#include "MQTTClient.h"
#include "errcode.h"
#include "../wifi/wifi_connect.h"
#include "../app_main.h"
#include "../dht11/dht11.h"
#include "../led/led.h"
#include "securec.h"

#ifndef unused
#define unused(var)     (void)(var)
#endif

osThreadId_t mqtt_init_task_id; // mqtt订阅数据任务

#define KEEP_ALIVE_INTERVAL 120
#define DELAY_TIME_MS 100


char g_send_buffer[260] = {0}; // 发布数据缓冲区
char g_response_id[100] = {0}; // 保存命令id缓冲区

MQTTClient_message pubmsg = MQTTClient_message_initializer;
MQTTClient_deliveryToken token;

// 全局定义静态缓冲区（避免函数内反复分配）
static char topicBuf[256] = {0};
static char dataBuf[1024] = {0};
#define		JSON_Tree_Format	"{ \n "					\
                                "\"services\": [{ \n"		\
                                "\"service_id\": \"smartRoom\", \n"	\
                                "\"properties\": { \n"	\
                                    "\"Temp\":  \"%s\", \n"	\
                                    "\"Humi\":  \"%s\", \n"	\
                                    "\"Lumi\":  \"%s\", \n"	\
                                    "\"LampST\":  \"%s\", \n"\
                                    "\"CondST\":  \"%s\", \n"\
                                    "\"VentST\":  \"%s\", \n"\
                                    "\"Smoke\":  \"%s\", \n"\
                                    "\"CO2\":  \"%s\" \n"\
                                    "}, \n"	\
                                "\"event_time\": \"\" \n"	\
                                "} \n"	\
                                "] \n"	\
                                "}\n"
                                

char A_JSON_Tree[512] = {0};	// 存放JSON树

char g_response_buf[160] = {0}; // 命令响应 JSON（response_name 与云平台命令名一致）
uint8_t g_cmdFlag;
MQTTClient client;
volatile MQTTClient_deliveryToken deliveredToken;
extern int MQTTClient_init(void);
static osal_mutex g_mux_id;

extern DHT11_Data_TypeDef DHT11_Data;  //存放温度数据
extern char LampSt[4] ;//灯状态
extern int lampState;

extern char CondiSt[4];//空调状态
extern int condiState;

extern char VentSt[4];//排风扇状态
extern int ventState;

extern char SmokeSt[16];//烟雾传感器
extern char CO2St[16];//二氧化碳浓度

extern uint16_t ldr_value;

/* 从 JSON 中按 key 提取字符串值（云平台 paras 均为 string） */
static int extract_json_string_value(const char *json, const char *key, char *out, size_t out_len)
{
    char key_pat[48] = {0};
    const char *p = NULL;
    size_t i = 0;

    if (json == NULL || key == NULL || out == NULL || out_len == 0) {
        return -1;
    }
    snprintf_s(key_pat, sizeof(key_pat), sizeof(key_pat) - 1, "\"%s\"", key);
    p = strstr(json, key_pat);
    if (p == NULL) {
        return -1;
    }
    p = strchr(p, ':');
    if (p == NULL) {
        return -1;
    }
    p++;
    while (*p == ' ' || *p == '\t') {
        p++;
    }
    if (*p == '"') {
        p++;
    }
    while (*p != '\0' && *p != '"' && *p != ',' && *p != '}' && i < out_len - 1) {
        out[i++] = *p++;
    }
    out[i] = '\0';
    return (i > 0) ? 0 : -1;
}

/* 解析云平台下发的 3 条命令（SetLamp / SetCond / SetVent） */
static void handle_cloud_command(const char *payload)
{
    char cmd_name[32] = {0};
    char para_val[8] = {0};
    const char *result = "fail";

    if (extract_json_string_value(payload, "command_name", cmd_name, sizeof(cmd_name)) != 0) {
        return;
    }

    if (strcmp(cmd_name, "SetLamp") == 0) {
        if (extract_json_string_value(payload, "LampStatus", para_val, sizeof(para_val)) == 0) {
            if (strcmp(para_val, "ON") == 0) {
                lampState = 0;
                led_on(1);
                snprintf_s(LampSt, sizeof(LampSt), sizeof(LampSt) - 1, "ON");
                result = "success";
            } else if (strcmp(para_val, "OFF") == 0) {
                lampState = 1;
                led_off(1);
                snprintf_s(LampSt, sizeof(LampSt), sizeof(LampSt) - 1, "OFF");
                result = "success";
            }
        }
        printf("[MQTT] Command SetLamp, LampStatus=%s, Result=%s\r\n", para_val, result);
    } else if (strcmp(cmd_name, "SetCond") == 0) {
        if (extract_json_string_value(payload, "CondStatus", para_val, sizeof(para_val)) == 0) {
            if (strcmp(para_val, "ON") == 0) {
                condiState = 1;
                snprintf_s(CondiSt, sizeof(CondiSt), sizeof(CondiSt) - 1, "ON");
                result = "success";
            } else if (strcmp(para_val, "OFF") == 0) {
                condiState = 0;
                snprintf_s(CondiSt, sizeof(CondiSt), sizeof(CondiSt) - 1, "OFF");
                result = "success";
            }
        }
        printf("[MQTT] Command SetCond, CondStatus=%s, Result=%s\r\n", para_val, result);
    } else if (strcmp(cmd_name, "SetVent") == 0) {
        if (extract_json_string_value(payload, "VentStatus", para_val, sizeof(para_val)) == 0) {
            if (strcmp(para_val, "ON") == 0) {
                ventState = 1;
                snprintf_s(VentSt, sizeof(VentSt), sizeof(VentSt) - 1, "ON");
                result = "success";
            } else if (strcmp(para_val, "OFF") == 0) {
                ventState = 0;
                snprintf_s(VentSt, sizeof(VentSt), sizeof(VentSt) - 1, "OFF");
                result = "success";
            }
        }
        printf("[MQTT] Command SetVent, VentStatus=%s, Result=%s\r\n", para_val, result);
    } else {
        return;
    }

    snprintf_s(g_response_buf, sizeof(g_response_buf), sizeof(g_response_buf) - 1,
               "{\"result_code\": 0,\"response_name\": \"%s\",\"paras\": {\"Result\": \"%s\"}}",
               cmd_name, result);
    g_cmdFlag = 1;
}

// 创建JSON树
//===================================================================================================
static void Setup_JSON_Tree_JX(void)
{
    char tempStr[16] = {0};
    char humiStr[16] = {0};
    char lumiStr[16] = {0};

    printf(" into setup json\n");
    snprintf_s(tempStr, sizeof(tempStr), sizeof(tempStr) - 1, "%d.%d",
               DHT11_Data.temp_high8bit, DHT11_Data.temp_low8bit);
    snprintf_s(humiStr, sizeof(humiStr), sizeof(humiStr) - 1, "%d.%d",
               DHT11_Data.humi_high8bit, DHT11_Data.humi_low8bit);
    snprintf_s(lumiStr, sizeof(lumiStr), sizeof(lumiStr) - 1, "%d", ldr_value);

    memset(A_JSON_Tree, 0, sizeof(A_JSON_Tree));
    snprintf_s(A_JSON_Tree, sizeof(A_JSON_Tree), sizeof(A_JSON_Tree) - 1,
               JSON_Tree_Format, tempStr, humiStr, lumiStr, LampSt, CondiSt, VentSt, SmokeSt, CO2St);

    printf("\r\n-------------------- create JSON tree -------------------\r\n");

    printf("%s", A_JSON_Tree);

    printf("\r\n--------------------create JSON tree  -------------------\r\n");
}


/* 回调函数，处理连接丢失 */
void connlost(void *context, char *cause)
{
    unused(context);
    printf("Connection lost: %s\n", cause);
}
int mqtt_subscribe(const char *topic)
{
    printf("subscribe start\r\n");
    MQTTClient_subscribe(client, topic, 1);
    return 0;
}

int mqtt_publish(const char *topic, char *msg)
{

    int ret = 0;
    pubmsg.payload = msg;
    pubmsg.payloadlen = (int)strlen(msg);
    pubmsg.qos = 1;
    pubmsg.retained = 0;
    //printf("[payload]:  %s, [topic]: %s\r\n", msg, topic);
    ret = MQTTClient_publishMessage(client, topic, &pubmsg, &token);

    if (ret != MQTTCLIENT_SUCCESS) {
        printf("mqtt publish failed\r\n");
        return ret;
    }

    return ret;
}

/* 回调函数，处理消息到达 */
void delivered(void *context, MQTTClient_deliveryToken dt)
{
    unused(context);
   // printf("Message with token value %d delivery confirmed\n", dt);

    deliveredToken = dt;
}
// 解析字符串并保存到数组中
void parse_after_equal(const char *input, char *output)
{
    const char *equalsign = strchr(input, '=');
    if (equalsign != NULL) {
        // 计算等于号后面的字符串长度
        strcpy(output, equalsign + 1);
    }
}
/* 回调函数，处理接收到的消息 */
int messageArrived(void *context, char *topic_name, int topic_len, MQTTClient_message *message)
{
    unused(context);
    uint16_t data_len = message->payloadlen;

    // 新增长度校验，避免内存越界
    if (topic_len >= (int)sizeof(topicBuf)) {
        printf("Topic length exceeds buffer size!\n");
        topic_len = sizeof(topicBuf) - 1; // 截断保护
    }
    if (data_len >= sizeof(dataBuf)) {
        printf("Data length exceeds buffer size!\n");
        data_len = sizeof(dataBuf) - 1; // 截断保护
    }

    memset(topicBuf, 0, sizeof(topicBuf));
    memcpy(topicBuf, topic_name, topic_len);
    topicBuf[topic_len] = '\0';
    memset(dataBuf, 0, sizeof(dataBuf));
    memcpy(dataBuf, (char *)message->payload, data_len);
    dataBuf[data_len] = '\0';

    // 打印接收日志
    printf("[MQTT] Receive topic: %s, data: %s \r\n", topicBuf, dataBuf);
    printf( "[MQTT] Topic len: %d, Data len: %d\r\n", topic_len, data_len);

    handle_cloud_command(dataBuf);

    if (g_cmdFlag) {
        parse_after_equal(topic_name, g_response_id);
        snprintf_s(g_send_buffer, sizeof(g_send_buffer), sizeof(g_send_buffer) - 1,
                   MQTT_CLIENT_RESPONSE, g_response_id);
    }

    memset((char *)message->payload, 0, message->payloadlen);
    MQTTClient_freeMessage(&message);
    MQTTClient_free(topic_name);

    return 1;
}

static errcode_t mqtt_connect(void)
{
    int ret;
    MQTTClient_connectOptions conn_opts = MQTTClient_connectOptions_initializer;
    /* 初始化MQTT客户端 */
    MQTTClient_init();
    /* 创建 MQTT 客户端 */
    ret = MQTTClient_create(&client, SERVER_IP_ADDR, CLIENT_ID, MQTTCLIENT_PERSISTENCE_NONE, NULL);
    if (ret != MQTTCLIENT_SUCCESS) {
        printf("Failed to create MQTT client, return code %d\n", ret);
        return ERRCODE_FAIL;
    }
    conn_opts.keepAliveInterval = KEEP_ALIVE_INTERVAL;
    conn_opts.cleansession = 1;
#ifdef IOT
    conn_opts.username = DEVICEID;
    conn_opts.password = CLIENTPASSWORD;
#endif
    // 绑定回调函数
    MQTTClient_setCallbacks(client, NULL, connlost, messageArrived, delivered);

    // 尝试连接
    if ((ret = MQTTClient_connect(client, &conn_opts)) != MQTTCLIENT_SUCCESS) {
        printf("Failed to connect, return code %d\n", ret);
        MQTTClient_destroy(&client); // 连接失败时销毁客户端
        return ERRCODE_FAIL;
    }
    printf("Connected to MQTT broker!\n");
    osDelay(DELAY_TIME_MS);
    // 订阅MQTT主题
    mqtt_subscribe(MQTT_CMDTOPIC_SUB);

    return ERRCODE_SUCC;
}

void mqtt_init_task(const char *argument)
{
    unused(argument);
    osDelay(DELAY_TIME_MS);
    mqtt_connect();

    while(1){
            // 响应平台命令部分
        osDelay(DELAY_TIME_MS); // 需要延时 否则会发布失败
        if (g_cmdFlag) {
            snprintf_s(g_send_buffer, sizeof(g_send_buffer), sizeof(g_send_buffer) - 1,
                       MQTT_CLIENT_RESPONSE, g_response_id);
            // 设备响应命令
            osal_mutex_lock_timeout(&g_mux_id, 10);//增加互斥锁，防止多进程冲突
            mqtt_publish(g_send_buffer, g_response_buf);
            osal_mutex_unlock(&g_mux_id);
            g_cmdFlag = 0;
            memset(g_response_id, 0, sizeof(g_response_id));
        }

        printf("construct json tree\r\n");
        Setup_JSON_Tree_JX();
        mqtt_publish(MQTT_DATATOPIC_PUB, A_JSON_Tree);
        memset(A_JSON_Tree, 0, sizeof(A_JSON_Tree));
        osDelay(DELAY_TIME_MS);   //延时1000Ms
        //osal_msleep(1000);  //每1秒采集一次
    }

}

/*********************************************************************
 * 函数名：mqtt_app_start
 * 描述：MQTT应用启动入口（创建MQTT任务）
 * 参数：无
 * 返回值：ERRCODE_SUCC(0)-成功，ERRCODE_FAIL(-1)-失败
 ********************************************************************/
void mqtt_app_start(void)
{
    // osal_kthread_lock();
	 
	// osal_task *task1 = osal_kthread_create((osal_kthread_handler)mqtt_init_task, 0, "mqtt_init_task", 0x3000);
	// osal_kthread_set_priority(task1, 10);
	// printf("Create mqtt_init_task succ.\r\n");

	// osal_kthread_unlock();

    // printf("Enter network_wifi_mqtt_example()!");

    // 配置新任务的属性
    osThreadAttr_t options;
    options.name = "mqtt_init_task";     // 任务名称
    options.attr_bits = 0;               // 属性位
    options.cb_mem = NULL;               // 控制块内存地址
    options.cb_size = 0;                 // 控制块大小
    options.stack_mem = NULL;            // 栈内存地址
    options.stack_size = 0x6000;         // 栈大小（12KB）
    options.priority = osPriorityNormal; // 任务优先级

    // 创建并启动MQTT初始化任务
    mqtt_init_task_id = osThreadNew((osThreadFunc_t)mqtt_init_task, NULL, &options);
    if (mqtt_init_task_id != NULL) {
        printf("ID = %d, Create mqtt_init_task_id is OK!", mqtt_init_task_id);
    }


}

