#ifndef _MQTT_H
#define _MQTT_H

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
#include "pinctrl.h"
#include "platform_core_rom.h"


#endif


int mqtt_publish(const char *topic, char *msg);

void mqtt_app_start(void);
void mqtt_init_task(const char *argument);


