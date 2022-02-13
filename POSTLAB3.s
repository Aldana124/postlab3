; Archivo: lab3.s
; Dispositivo: PIC16F887
; Autor: Diego Aldana

; Programa: contador binario de 4 bits en 7 segmentos
   
; Hardware: CRISTAL EN EL PUERTO C

; Creado: 07/02/2022
; Ult. modificaciíon: 07/02/2022
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

 // config statements should precede project file includes.
PROCESSOR 16F887
#include <xc.inc>
    
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)


PSECT udata_bank0		;common memory
  CONT:		DS 1
PSECT resvect, class=CODE, abs, delta =2
;-----------RESET-------------
 ORG 00H
 resvect:
    GOTO MAIN
	
    PSECT code, delta =2, abs
 ;------CONFIGURACIÓN--------
 ORG 100H
 MAIN:
    BSF STATUS, 5 ; BANCO 01
    BSF STATUS, 6 ; BANCO 11
    CLRF ANSEL ; DIGITALES
    CLRF ANSELH
    BCF STATUS, 6 ; BANCO 01
    BSF TRISA, 0; RA0 COMO ENTRADA
    BSF TRISA, 1; RA1 COMO ENTRADA
    BCF TRISE, 0
    MOVLW 0x00 ; HABILITAR SOLO 4BITS
    MOVWF TRISC
    MOVLW 0xF0 ; HABILITAR SOLO 4BITS 
    MOVWF TRISD
    MOVLW 0x00 ; HABILITAR SOLO 4BITS
    MOVWF TRISB
    BANKSEL PORTE
    CLRF PORTB
    CLRF CONT			; Reinicio de contador
    CLRF PORTC	
    CLRF PORTD
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador
    CALL    CONFIG_TMR0	    ; Configuración de TMR0
    BANKSEL PORTD	    ; Cambio a banco 00
    
LOOP:
    BTFSS   T0IF	    ; Verificamos interrupción del TMR0
    GOTO    LOOP	    ; Si aún no ha pasado el tiempo, evaluamos bandera nuevamente
    
    ; Cuando se activa la bander de interrupción del TMR0 se ejectun estas instrucciones
    ;-- Programamos lo que queremos que el uC haga luego del retardo
    CALL    RESET_TMR0
    INCF    PORTB
    BTFSC  PORTB, 3
    CALL INC10
    GOTO    CHECKBOTN  
  ;-------CICLO---------     
CHECKBOTN:
    BTFSC PORTA, 0 ; VEMOS SI BOTÓN ESTÁ PRESIONADO
    CALL ANTIREBOTE
    BTFSC PORTA, 1 ; VEMOS SI BOTÓN ESTÁ PRESIONADO
    CALL ANTIREBOTE2
    CALL ALARMA
    GOTO LOOP

 ;----SUBRUTINAS---------   
 INC10:
    BTFSC PORTB, 1
    CALL INC102
    RETURN
    
 INC102:
    INCF PORTD
    CLRF PORTB
    RETURN
 
 ALARMA:
    MOVF CONT, W
    SUBWF PORTD,W
    BTFSC ZERO
    INCF PORTE
    RETURN
    
    
    
    
ANTIREBOTE:
    BTFSC PORTA, 0 ; VEMOS SI EL BOTÓN NO ESTÁ PRESIONADO
    GOTO ANTIREBOTE
    MOVF    CONT, W; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTC		; Guardamos caracter de CONT en ASCII
    INCF    CONT		; Incremento de contador
    BTFSC   CONT, 7		; Verificamos que el contador no sea mayor a 15
    CLRF    CONT		; Si es mayor a 15, reiniciamos contador	
    RETURN
      
ANTIREBOTE2:
    BTFSC PORTA, 1 ; VEMOS SI EL BOTÓN NO ESTÁ PRESIONADO
    GOTO ANTIREBOTE2
    MOVF    CONT, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII
    MOVWF   PORTC		; Guardamos caracter de CONT en ASCII
    DECF    CONT		; Incremento de contador
    BTFSC   CONT, 7		; Verificamos que el contador no sea mayor a 15
    RETURN
    
 ;------------- SUBRUTINAS ---------------
CONFIG_RELOJ:    CLRF    CONT		; Si es mayor a 7, reiniciamos contador

    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BSF	    OSCCON, 4	    ; IRCF<2:0> -> 101 2MHz
    return
    
; Configuramos el TMR0 para obtener un retardo de 100ms
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como CONTADOR
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   61
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    return 
    
 ; Cada vez que se cumple el tiempo del TMR0 es necesario reiniciarlo.
RESET_TMR0:
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   61
    MOVWF   TMR0	    ; 100ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    return  
    
    ORG 200h    
TABLA:
    CLRF    PCLATH		; Limpiamos registro PCLATH
    BSF	    PCLATH, 1		; Posicionamos el PC en dirección 02xxh
    ANDLW   0x0F		; no saltar más del tamaño de la tabla
    ADDWF   PCL			; Apuntamos el PC a caracter en ASCII de CONT
    RETLW   00000110B			; ASCII char 1
    RETLW   01011011B			; ASCII char 2
    RETLW   01001111B			; ASCII char 3
    RETLW   01100110B			; ASCII char 4
    RETLW   01101101B			; ASCII char 5
    RETLW   01111101B			; ASCII char 6
    RETLW   00000111B			; ASCII char 7
    RETLW   01111111B			; ASCII char 8
    RETLW   01101111B			; ASCII char 9
    RETLW   01110111B			; ASCII char 10
    RETLW   01111100B			; ASCII char 11
    RETLW   00111001B			; ASCII char 12
    RETLW   01011110B			; ASCII char 13
    RETLW   01111001B			; ASCII char 14
    RETLW   01110001B			; ASCII char 15
    RETLW   00111111B			; ASCII char 0
END