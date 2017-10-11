/**
*****************************************************************************
**
**  File        : main.c
**
**  Abstract    : main function.
**
**  Functions   : main
**
**  Environment : Atollic TrueSTUDIO/STM32
**                STMicroelectronics STM32F10x Standard Peripherals Library
**
**  Distribution: The file is distributed “as is,” without any warranty
**                of any kind.
**
**  (c)Copyright Atollic AB.
**  You may use this file as-is or modify it according to the needs of your
**  project. Distribution of this file (unmodified or modified) is not
**  permitted. Atollic AB permit registered Atollic TrueSTUDIO(R) users the
**  rights to distribute the assembled, compiled & linked contents of this
**  file as part of an application binary file, provided that it is built
**  using the Atollic TrueSTUDIO(R) toolchain.
**
**
*****************************************************************************
*/

/* Includes */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "stm32f10x.h"
#include "timers.h"
#include "processes.h"
#include "usart_diag.h"
#include "uart_power.h"
#include "io.h"
#include "usart_xbee.h"
#include "fifobuf.h"
#include "interrupt.h"
#include "lamps_on.h"
#include "usart_gsm.h"
#include "mess.h"
#include "eeprom.h"

char SoftDate[]=__DATE__;
char SoftTime[]=__TIME__;

void RCC_Configuration(void)
{
  /* PCLK1 = HCLK/4 */
  RCC_PCLK1Config(RCC_HCLK_Div4);

  /* TIM2 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);

}

void PresentationMessages(void){
	unsigned int i, Pos;
	char buf[4], bufTr[24];
	CMsgToUDiagLn(DevPresentationMsg);
	CMsgToUDiagLn(AuthorPresentationMsg);
	CMsgToUDiagLn(HardPresentationMsg);
	CMsgToUDiag(SoftPresentationMsg);
	//MsgToUDiagLn(SoftDate);
	memcpy(buf,SoftDate+9,2);
	buf[2]=0;
	i=atoi(buf);
	Pos=sprintf(bufTr,"%02u",i);
	i=0;
	if (strstr(SoftDate,"Jan")!=NULL){
		i=1;
	}
	if (strstr(SoftDate,"Feb")!=NULL){
		i=2;
	}
	if (strstr(SoftDate,"Mar")!=NULL){
		i=3;
	}
	if (strstr(SoftDate,"Apr")!=NULL){
		i=4;
	}
	if (strstr(SoftDate,"May")!=NULL){
		i=5;
	}
	if (strstr(SoftDate,"Jun")!=NULL){
		i=6;
	}
	if (strstr(SoftDate,"Jul")!=NULL){
		i=7;
	}
	if (strstr(SoftDate,"Aug")!=NULL){
		i=8;
	}
	if (strstr(SoftDate,"Sep")!=NULL){
		i=9;
	}
	if (strstr(SoftDate,"Oct")!=NULL){
		i=10;
	}
	if (strstr(SoftDate,"Nov")!=NULL){
		i=11;
	}
	if (strstr(SoftDate,"Dec")!=NULL){
		i=12;
	}
	Pos+=sprintf(bufTr+Pos,"%02u",i);
	memcpy(buf,SoftDate+4,2);
	buf[2]=0;
	i=atoi(buf);
	Pos+=sprintf(bufTr+Pos,"%02u.",i);
	//MsgToUDiagLn(SoftTime);
	memcpy(buf,SoftTime,2);
	buf[2]=0;
	i=atoi(buf);
	Pos+=sprintf(bufTr+Pos,"%02u",i);
	memcpy(buf,SoftTime+3,2);
	buf[2]=0;
	i=atoi(buf);
	sprintf(bufTr+Pos,"%02u",i);
	MsgToUDiagLn(bufTr);
	MsgToUDiagLn("CTRL-C diagnostyka i konfiguracja");
	sprintf(bufTr,"sizeof(EConfig)=%u",sizeof(EConfig));
	MsgToUDiagLn(bufTr);
}



/*void MainProcess(void){
	static uint32_t i;
	char buf[20];
	if (MainPTimer>0)
		return;
	sprintf(buf,"A%u",i++);
	MainPTimer=SECONDS(1)/2;
	MsgToUPowerLn(buf);
	MsgToUDiagLn(buf);
}*/

int main(void){
	int i;
//	char buf[32];
	RCC_Configuration();
	GPIO_Configuration();
	TIM2_Configuration();
	USARTpower_Configuration();
	USARTdiag_Configuration();
	USARTgsm_Configuration();
	USARTXBEE_Configuration();
	EEPROM_Configuration();
	FIFOBufInit(&sUPowerTBuf,UPowerTBuf,UPOWERTBUF);
	FIFOBufInit(&sUPowerRBuf,UPowerRBuf,UPOWERRBUF);
	FIFOBufInit(&sUDiagTBuf,UDiagTBuf,UDIAGTBUF);
	FIFOBufInit(&sUDiagRBuf,UDiagRBuf,UDIAGRBUF);
	FIFOBufInit(&sUGsmTBuf,UGsmTBuf,UGSMTBUF);
	FIFOBufInit(&sUGsmRBuf,UGsmRBuf,UGSMRBUF);
	FIFOBufInit(&sUXbeeTBuf,UXbeeTBuf,UXBEETBUF);
	FIFOBufInit(&sUXbeeRBuf,UXbeeRBuf,UXBEERBUF);
	FIFOLampMsgInit();
	ParseBufInit();
	NVIC_Configuration();
	for	 (i=0 ; i<4 ; i++){
		AllowedPwr0[i]=100;
		Power0[i]=20;
		AllowedPwr1[i]=100;
		Power1[i]=20;
		PwrPresent[i]=PWRPRESENT;
	}
	PresentationMessages();
	Load_Configuration();
	while(1){
		Process_Init(USARTdiag_RProcess);
		Process_Init(LampsOn_Process);
		Process_Init(USARTpower_Process);
		Process_Init(USARTpower_Process);
		Process_Init(GSM_Process);
		Process_Init(GSMR_Process);
		Process_Init(UDiagTypeProcess);
		Process_Init(Xbee_Process);
		Process_Init(XbeeR_Process);
		Process_Scheduler();
	}
}

#ifdef  USE_FULL_ASSERT

/**
  * @brief  Reports the name of the source file and the source line number
  *   where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t* file, uint32_t line)
{
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */

  /* Infinite loop */
  while (1)
  {
  }
}
#endif

/*
 * Minimal __assert_func used by the assert() macro
 * */
void __assert_func(const char *file, int line, const char *func, const char *failedexpr)
{
  while(1)
  {}
}

/*
 * Minimal __assert() uses __assert__func()
 * */
void __assert(const char *file, int line, const char *failedexpr)
{
   __assert_func (file, line, NULL, failedexpr);
}

#ifdef USE_SEE
#ifndef USE_DEFAULT_TIMEOUT_CALLBACK
/**
  * @brief  Basic management of the timeout situation.
  * @param  None.
  * @retval sEE_FAIL.
  */
uint32_t sEE_TIMEOUT_UserCallback(void)
{
  /* Return with error code */
  return sEE_FAIL;
}
#endif
#endif /* USE_SEE */

  