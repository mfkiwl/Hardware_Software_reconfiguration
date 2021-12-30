#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "platform.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "xtime_l.h"

#define BRAM_CTRL_ADDR 0x40000000
#define IP_STARTADDR_SET 0x41220000
#define OPR_START_STOP_ADDR 0x41210000
#define START_OPR_CHANNEL 1
#define STOP_OPR_CHANNEL 2
#define MUX_SEL_ADDR 0x41200000
#define DATA_MUX_CHANNEL 1
#define TWIDDLE_MUX_CHANNEL 2
#define START_STAGE_CHANNEL 1
#define FLAG_CHANNEL 2

XGpio gpio0, gpio1, gpio2, gpio3;

uint32_t *fft_statusFlags = (uint32_t*)(XPAR_AXI_GPIO_3_BASEADDR + 0x0008);
uint32_t *fft_startStageAssert = (uint32_t*)XPAR_AXI_GPIO_3_BASEADDR;
uint32_t *startAddr_set = (uint32_t*)XPAR_AXI_GPIO_2_BASEADDR;
uint32_t *startOpr = (uint32_t*)XPAR_AXI_GPIO_1_BASEADDR;
uint32_t *stopOpr =  (uint32_t*)(XPAR_AXI_GPIO_1_BASEADDR + 0x0008);
uint32_t *dataMux = (uint32_t*)XPAR_AXI_GPIO_0_BASEADDR;
uint32_t *twiddleMux = (uint32_t*)(XPAR_AXI_GPIO_0_BASEADDR + 0x0008);

static inline void toggle_startStage(){
	*fft_startStageAssert = (uint32_t*)0x00000001;
	while(1){
		if (*fft_statusFlags & 0x00000001){
			*fft_startStageAssert = (uint32_t*)0x00000000;
			return;
		}
	}
}


int main()
{
	XTime tStart, tEnd;
	init_platform();
	print("Program Start\n");
	XGpio_Initialize(&gpio0, XPAR_AXI_GPIO_0_DEVICE_ID);
	XGpio_Initialize(&gpio1, XPAR_AXI_GPIO_1_DEVICE_ID);
	XGpio_Initialize(&gpio2, XPAR_AXI_GPIO_2_DEVICE_ID);
	XGpio_Initialize(&gpio3, XPAR_AXI_GPIO_3_DEVICE_ID);

	// GPIO0 -> Mux select lines
	// GPIO1 -> Start, Stop operation
	// GPIO2 -> Set Start Address
	// GPIO3 -> Start stage, read flags
	XGpio_SetDataDirection(&gpio0, DATA_MUX_CHANNEL, 0x000000);
	XGpio_SetDataDirection(&gpio0, TWIDDLE_MUX_CHANNEL, 0x000);
	XGpio_SetDataDirection(&gpio1, START_OPR_CHANNEL, 0x0);
	XGpio_SetDataDirection(&gpio1, STOP_OPR_CHANNEL, 0x0);
	XGpio_SetDataDirection(&gpio2, 1, 0x000000);
	XGpio_SetDataDirection(&gpio3, START_STAGE_CHANNEL, 0x0);
	XGpio_SetDataDirection(&gpio3, FLAG_CHANNEL, 0x1);

	uint32_t *bram = (uint32_t*)BRAM_CTRL_ADDR;

    *startAddr_set = (uint32_t*)0x00000000;		// Set Start Address
    //XGpio_DiscreteWrite(&gpio2, 1, 0x000000);

    int stage = 1;
    //uint32_t fft_statusFlag;


    XTime_GetTime(&tStart);
    //XGpio_DiscreteWrite(&gpio1, START_OPR_CHANNEL, 0x00000001);
    *startOpr = 0x00000001;

    while(stage < 4){
    	//fft_statusFlag = XGpio_DiscreteRead(&gpio3, FLAG_CHANNEL);
    	if (*fft_statusFlags & 0x00000001){ // Start if ready flag is asserted
    		if (stage == 1){
    			*dataMux = (uint32_t*)0x00fac688;
    			*twiddleMux = (uint32_t*)0x00000000;
				//XGpio_DiscreteWrite(&gpio0, DATA_MUX_CHANNEL, 0x00fac688);
				//XGpio_DiscreteWrite(&gpio0, TWIDDLE_MUX_CHANNEL, 0x00000000);
				stage++;
				toggle_startStage();
			}
			else if (stage == 2){
				*dataMux = (uint32_t*)0x00f74650;
				*twiddleMux = (uint32_t*)0x00000410;
				//XGpio_DiscreteWrite(&gpio0, DATA_MUX_CHANNEL, 0x00f74650);
				//XGpio_DiscreteWrite(&gpio0, TWIDDLE_MUX_CHANNEL, 0x00000410);
				stage++;
				toggle_startStage();
			}
			else if (stage == 3){
				*dataMux = (uint32_t*)0x00ee9ca0;
				*twiddleMux = (uint32_t*)0x00000688;
				//XGpio_DiscreteWrite(&gpio0, DATA_MUX_CHANNEL, 0x00ee9ca0);
				//XGpio_DiscreteWrite(&gpio0, TWIDDLE_MUX_CHANNEL, 0x00000688);
				stage++	;
				toggle_startStage();
			}
    	}
    }

    *startOpr = 0x00000000;
    *stopOpr = 0x00000001;
    //XGpio_DiscreteWrite(&gpio1, START_OPR_CHANNEL, 0x00000000);
    //XGpio_DiscreteWrite(&gpio1, STOP_OPR_CHANNEL, 0x00000001);

    while(1){
    	//fft_statusFlag = XGpio_DiscreteRead(&gpio3, FLAG_CHANNEL);
    	if(!(*fft_statusFlags & 0x00000003)){	// Wait until both busy and ready flags are deasserted (idle state)
    		break;
    	}
    }

    *stopOpr = 0x00000000;
    XTime_GetTime(&tEnd);

    uint32_t bram_data = 0;
    for(int i = 0; i < 16; i++){
    	bram_data = *bram;
        bram += 1;
        xil_printf("0x%08x", bram_data);
        print("\n");
    }

    printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
    printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));

    //XGpio_DiscreteWrite(&gpio1, STOP_OPR_CHANNEL, 0x00000000);

    print("Demo complete!");
    cleanup_platform();
    return 0;
}
