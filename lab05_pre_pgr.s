/*	
    Archivo:		lab04_pre_pgr.s
    Dispositivo:	PIC16F887
    Autor:		Gerardo Paz 20173
    Compilador:		pic-as (v2.30), MPLABX V6.00

    Programa:		RBIE y T0IE 
    Hardware:		Botones en puerto B
			Leds en puerto A

    Creado:			14/02/22
    Última modificación:	15/02/22	
*/
    
PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
    
 /*---------------- RESET ----------------*/
 PSECT resVect, class=CODE, abs, delta=2	
 ORG 00h					
 resVect:
       PAGESEL main
       GOTO    main
       
 /*--------------- Variables --------------*/  
 UP	EQU 0
 DOWN	EQU 1
	
 PSECT udata_shr		    //Memoria compartida
 W_TEMP:	    DS  1	    
 STATUS_TEMP:	    DS  1	    
    
 
 /*-------------- Interrupciones ---------------*/   
 PSECT intVect, class=CODE, abs, delta=2    
 ORG 04h
 
 push:
    MOVWF   W_TEMP	    //Movemos W en la temporal
    SWAPF   STATUS, W	    //Pasar el SWAP de STATUS a W
    MOVWF   STATUS_TEMP	    //Guardar STATUS SWAP en W	
    
 isr:    
    BTFSC   RBIF	    //Revisar la interrupción de puerto B
    CALL    int_iocb 
    
 pop:
    SWAPF   STATUS_TEMP, W  //Regresamos STATUS a su orden original y lo guaramos en W
    MOVWF   STATUS	    //Mover W a STATUS
    SWAPF   W_TEMP, F	    //Invertimos W_TEMP y se guarda en F
    SWAPF   W_TEMP, W	    //Volvemos a invertir W_TEMP para llevarlo a W
    RETFIE
    
    
 /*------------ Subrutinas de interrupción ------------*/
 int_iocb:	
    BANKSEL PORTB
    BTFSS   PORTB, UP
    INCF    PORTC	//Incremento
    
    BTFSS   PORTB, DOWN
    DECF    PORTC	//Decremento
    
    BCF	    RBIF	//Limpiar bandera
    
    RETURN
    
    
 /*----------------- COONFIGURACIÓN uC --------------------*/
 PSECT code, delta=2, abs	
 ORG 100h			//Dirección 100% seguro de que ya pasó el reseteo
 
 main:
    CALL    setup_io
    CALL    setup_io_ocB
    CALL    setup_int
    BANKSEL PORTA
    
 loop:
    GOTO    loop   

setup_io_ocB:
    BANKSEL IOCB
    BSF	    IOCB, UP
    BSF	    IOCB, DOWN
    
    BANKSEL PORTA
    MOVF    PORTB, W	//Se termina la condición de mismatch
    BCF	    RBIF	//Limpiar bandera
    
    RETURN  
 
 setup_io:
    
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	//Digital in/out on A and B
    
    BANKSEL TRISB
    BSF	    TRISB, UP	//RB0 in
    BSF	    TRISB, DOWN	//RB1 in
    
    BANKSEL TRISA
    CLRF    TRISC	//Port C out
    
    BANKSEL OPTION_REG
    BCF	    OPTION_REG, 7   //Pul up Port B enabled
    
    BANKSEL WPUB
    CLRF    WPUB	    //weak pull up disabled on all Port B
    BSF	    WPUB, UP
    BSF	    WPUB, DOWN	    //weak pull up enabled only on RB0 - RB1

    BANKSEL PORTA
    CLRF    PORTC
    CLRF    PORTB	//Puertos limpios
    
    RETURN
    
 setup_int:
    BSF	    GIE		    //Global interruptions Enabled
    BSF	    RBIE	    //PORTB change interrupt enabled
    BCF	    RBIF	    //Limpiar bandera 
    
    RETURN
    
 
 END