/*
 * @file idsec.c
 * @brief Plik generowany przez skrypt ChDate
 * @date 12-02-16 11:24:20
 *
 */
#include "idsec.h"
 __attribute__((section(".idsec"))) const IdSoft_t IDSoft={
	{
		'1' ^ SECKEY0,
		'2' ^ SECKEY1,
		'0' ^ SECKEY2,
		'2' ^ SECKEY3,
		'1' ^ SECKEY4,
		'6' ^ SECKEY5,
		'1' ^ SECKEY6,
		'1' ^ SECKEY7,
		'2' ^ SECKEY8,
		'4' ^ SECKEY9,
		'2' ^ SECKEY10,
		'0' ^ SECKEY11,
		0,
	},
	{
		'0' ^ SECKEY12,
		'0' ^ SECKEY13,
		'0' ^ SECKEY14,
		'0' ^ SECKEY15,
		'2' ^ SECKEY16,
		'7' ^ SECKEY17,
		0,
	},
	{
		SECKEY18,
		SECKEY19,
		SECKEY20,
		SECKEY21,
		SECKEY22,
		SECKEY23,
		SECKEY24,
		SECKEY25,
		SECKEY26,
		SECKEY27,
		SECKEY28,
		SECKEY29,
		SECKEY30,
		SECKEY31,
		SECKEY32,
		SECKEY33,
	},
};

void ReadProcessorID(unsigned long int *id){
	id[0]=*((unsigned long int *)(0x1FFFF7E8));
	id[1]=*((unsigned long int *)(0x1FFFF7E8+4));
	id[2]=*((unsigned long int *)(0x1FFFF7E8+8));
}


unsigned char DummyIDSoft(void){
	return IDSoft.SoftTimeStamp[0];
}



