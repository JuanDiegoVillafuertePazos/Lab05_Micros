;Archivo:	7segmentosdecimal.s
;Dispositivo:	    PIC16F887
;Autor:	    Juan Diego Villafuerte
;Compilador: pic-as (v2.30), MPLABX V5.40
;
;Programa:	
;Hardware:	LEDs en puestos A, 7 segmentos en puerto C, botones en puerto B
;
;Creado;	06 marzo 2021
;Ultima modificación:	    02marzo 2021

PROCESSOR 16F887
#include <xc.inc>
    ;configuration word 1

    CONFIG FOSC=INTRC_NOCLKOUT // Osilador interno sin salida
    CONFIG WDTE=OFF // WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=ON // PWRT eneable (espeera de 72ms al inicial)
    CONFIG MCLRE=OFF // El pin de MCLR se utiliza como I/O 
    CONFIG CP=OFF // Sin proteccion de código
    CONFIG CPD=OFF // Sin proteccion de datos
    
    CONFIG BOREN=OFF //Sin reinicio cuando el voltaje de alimentación baja de 4V
    CONFIG IESO=OFF // Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF // Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=ON // Programación en bajo voltaje permitida
    
    ;configuration word 2
    
    CONFIG WRT=OFF // Proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V // Reinicio abajo de 4V1 (BOR21V=2.1V)
    
    PSECT udata_bank0
	nibble: DS 2
	display: DS 2
	banderas: DS 1
    
	/*centena: DS 1
	decena: DS 1
	unidad: DS 1*/
    
	centenadis: DS 1
	decenadis: DS 1
	unidaddis: DS 1
    
	centenaC: DS 1
	decenaC: DS 1
	unidadC: DS 1
    
	numerador: DS 1
    
    
    PSECT udata_shr ;common memory
	W_TEMP: DS 1 ;1 byte
	STATUS_TEMP: DS 1 ;var: DS 5
	;var: DS 1
	
;_Para el vector reset   
    PSECT resVect, class=CODE, abs, delta=2
    ORG 00h	;posicion 0000h para el reset
    
resetVec:
	PAGESEL main
	goto main
    

    PSECT intVect, class=CODE, abs, delta=2
    ORG 04h	;posicion 0004h para el reset

push:	    ;guardar W y STATUS
    movwf  W_TEMP
    swapf STATUS,w
    movwf STATUS_TEMP
       
isr:
    btfsc RBIF	    ;Para revisar la interrupcion por cambio
    call boton	    
    btfsc INTCON,2  ;Para revisar el overflow del timer0
    call taimer
 
pop:	    ;desplegar los guardados de W y STATUS
    swapf STATUS_TEMP,w
    movwf STATUS
    swapf W_TEMP,f
    swapf W_TEMP,w
    retfie

    PSECT code, delta=2, abs
    ORG 100h
    
tabla7seg:
    clrf PCLATH
    bsf PCLATH,0
    ;andwf 0x0F
    
    addwf PCL

    retlw 00111111B	;0
    retlw 00000110B	;1
    retlw 01011011B	;2
    retlw 01001111B	;3
    retlw 01100110B	;4
    retlw 01101101B	;5
    retlw 01111101B	;6
    retlw 00000111B	;7
    retlw 01111111B	;8
    retlw 01100111B	;9
    retlw 01110111B	;A
    retlw 01111100B	;B
    retlw 00111001B	;C
    retlw 01011110B	;D
    retlw 01111001B	;E
    retlw 01110001B	;F   
    
main:
    call config_inter_eneable
    call config_io
    call config_ioc
    bsf banderas,0

loop:
    call separar
    call cargar
    
    clrf centenaC
    clrf decenaC
    ;clrf unidadC
    clrf numerador

    call division
   
    goto loop
   
boton:
    banksel PORTA
    btfss PORTB,0
    incf PORTA
    btfss PORTB,1
    decf PORTA

    bcf RBIF
    return

taimer:
    banksel PORTA
    call ress	    ;reset del timer
    clrf PORTB
    
    btfsc banderas,0
    goto display1
    btfsc banderas,1
    goto display0
    btfsc banderas,2
    goto display2
    btfsc banderas,3
    goto display3
    btfsc banderas,4
    goto display4
    
display0:
    movf display+1,w
    movwf PORTC
    bsf PORTB,3

    bcf banderas,1
    bsf banderas,2
    return
    
display1:
    movf display,w
    movwf PORTC
    bsf PORTB,4
    
    bcf banderas,0
    bsf banderas,1

    return
    
display2:
    movf centenadis,w
    movwf PORTD
    bsf PORTB,7
    
    bcf banderas,2
    bsf banderas,3
    return

display3:
    movf decenadis,w
    movwf PORTD
    bsf PORTB,6
    
    bcf banderas,3
    bsf banderas,4
    return
    
display4:
    movf unidaddis,w
    movwf PORTD
    bsf PORTB,5
    
    bcf banderas,4
    bsf banderas,0
    return

separar:
    movf PORTA,w
    andlw 0x0f
    movwf nibble
    
    swapf PORTA,w
    andlw 0x0f
    movwf nibble+1
    return
    
cargar:
    movf nibble,w 
    call tabla7seg
    movwf display
    
    movf nibble+1,w 
    call tabla7seg
    movwf display+1
    return
 
division:
    
    bcf   STATUS, 0
    movf  PORTA, w  
    movwf numerador
    movlw 100
    incf  centenaC
    subwf numerador, f
    btfsc STATUS, 0
    goto  $-3
    decf  centenaC
    addwf numerador
    
    movf  centenaC, w
    call  tabla7seg
    movwf centenadis
    
    bcf   STATUS, 0
    movlw 10
    incf  decenaC
    subwf numerador, f
    btfsc STATUS, 0
    goto  $-3
    decf  decenaC
    addwf numerador
    
    movf  decenaC, w
    call  tabla7seg
    movwf decenadis
    
    movf  numerador, w
    call  tabla7seg
    movwf unidaddis
    return
    
/*siguiente:
    movlw 1
    xorwf banderas, f*/
    
    /* 
	 funcionamiento Xor
    w     banderasP  |  banderasF
    0        0       |      0
    0        1       |      1
    1        0       |      1
    1        1       |      0
    */
    
config_io:
    
    banksel ANSEL
    clrf ANSEL
    clrf ANSELH
    
    banksel TRISA
    bsf TRISB,0
    bsf TRISB,1
    
    bcf TRISB,7
    bcf TRISB,6
    bcf TRISB,5
    bcf TRISB,4
    bcf TRISB,3
    
    clrf TRISC
    clrf TRISD
    clrf TRISA
    
    bcf OPTION_REG,7	  ;Para abilitar pull-ups
    bsf WPUB,0		  ;Para que el puerto B en 0,1 esten con el pull-up  
    bsf WPUB,1
    

    banksel PORTA
    clrf PORTA
    clrf PORTC
    clrf PORTD

    ;OPTION_REG_   
 
    banksel OPTION_REG
    bcf OPTION_REG,5 ;Para configurar como timer interno
    bcf OPTION_REG,3 ;Activar el prescaler para timer0
    
    bcf OPTION_REG,0 ;Cargar el prescaler
    bcf OPTION_REG,1 
    bsf OPTION_REG,2 
    
    ;_OSCCON
    
    banksel OSCCON
    bsf OSCCON,6     ;Config del osilador a 1MHz
    bcf OSCCON,5
    bcf OSCCON,4
    
    bsf OSCCON,0     ;osilador interno
    return    

config_ioc:
    
    banksel TRISA	;Para las interrupciones por cambio
    bsf IOCB,0
    bsf IOCB,1
    
    banksel PORTA
    movf PORTB,w
    bcf RBIF
    return
    
config_inter_eneable:
    
    bsf GIE	    ;encender interrupciones
    bsf RBIE	    ;interrupcion por cambio en el pueto b
    bcf RBIF	    ;borrar la bandera de la interrupcion en b
    bsf T0IE	    ;encender interrupcion timer0
    return
    
ress:
    
    movlw 160
    movwf TMR0
    bcf INTCON,2
    return 
    
end