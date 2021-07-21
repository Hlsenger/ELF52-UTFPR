        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

SYSCTL_RCGCGPIO_R               EQU     0x400FE608
SYSCTL_PRGPIO_R		        EQU     0x400FEA08
PORTEN_BIT                      EQU     1111111111111b
PORTN_LED_MASK                  EQU     0001100b
PORTF_LED_MASK                  EQU     1000100b



//PORTEN_BIT                      EQU     1000000100000b ; Habilita porta F e N

GPIO_PORTN_DATA_MASKED_R    	EQU     0x40064000
GPIO_PORTN_DATA_R    	        EQU     0x400643FC
GPIO_PORTN_DIR_R     	        EQU     0x40064400
GPIO_PORTN_DEN_R     	        EQU     0x4006451C

GPIO_PORTF_DATA_MASKED_R    	EQU     0x4005D000
GPIO_PORTF_DATA_R    	        EQU     0x4005D3FC
GPIO_PORTF_DIR_R     	        EQU     0x4005D400
GPIO_PORTF_DEN_R     	        EQU     0x4005D51C



initgpio    
            MOV R2, #PORTEN_BIT
            LDR R0, =SYSCTL_RCGCGPIO_R
            LDR R1, [R0] ; leitura do estado anterior
            ORR R1, R2 ; habilita port F e N
            STR R1, [R0] ; escrita do novo estado

            LDR R0, =SYSCTL_PRGPIO_R
initgpio_wait	
          LDR R2, [R0] ; leitura do estado atual
          TEQ R1, R2 ; clock do port N habilitado?
          BNE initgpio_wait ; caso negativo, aguarda


          ;;Configura porta N
          MOV R2, #00000011b ; Habilita bit 0(D2) e bit 1(D1)

          LDR R0, =GPIO_PORTN_DIR_R
          LDR R1, [R0] ; leitura do estado anterior
          ORR R1, R2 ; bit de saída
          STR R1, [R0] ; escrita do novo estado

          LDR R0, =GPIO_PORTN_DEN_R
          LDR R1, [R0] ; leitura do estado anterior
          ORR R1, R2 ; habilita função digital
          STR R1, [R0] ; escrita do novo estado

          ;;Configura porta F
          MOV R2, #00010001b ; Habilita bit 0(D4) e bit 4(D3)

          LDR R0, =GPIO_PORTF_DIR_R
          LDR R1, [R0] ; leitura do estado anterior
          ORR R1, R2 ; bit de saída
          STR R1, [R0] ; escrita do novo estado

          LDR R0, =GPIO_PORTF_DEN_R
          LDR R1, [R0] ; leitura do estado anterior
          ORR R1, R2 ; habilita função digital
          STR R1, [R0] ; escrita do novo estado

          BX LR

update_leds ;Atualiza os leds baseado no valor do contador no registrador R0
        PUSH {R1-R4}
        
        LDR R1, = GPIO_PORTF_DATA_MASKED_R ;Offset porta F
        LDR R2, = GPIO_PORTN_DATA_MASKED_R ;Endereco porta N

        ;Testa Led D4(bit 0)
        AND R3, R0,#0001b
        MOVS R4, R3
        
        ;Testa Led D3(bit 4)
        AND R3, R0,#0010b
        LSL R3, R3, #3
        ORR R3,R4
        
        STR R3, [R1,#PORTF_LED_MASK] ;Atualiza porta F
        
        ;Testa Led D2(bit 0)
        AND R3, R0,#0100b
        LSR R3, R3, #2
        MOVS R4,R3
        
        ;Testa Led D1(bit1)
        AND R3, R0,#1000b
        LSR R3, R3, #2
        ORR R3,R4
        
        STR R3, [R2,#PORTN_LED_MASK] ;Atualiza porta N
        
        
        
        POP {R1-R4}
        BX LR
        
     
__iar_program_start
        
main    
        BL initgpio ;;Inicializa portas GPIO F e N

        MOVS R0, #0 ;Zera contador
        
loop	
        
        BL update_leds
        
        ADDS R0,#1 ;;Soma 1 ao contador
        TEQ R0,#16 ;;Reseta o contador ao contar alem de 15
        IT EQ
          MOVEQ R0,#0

        MOVT R3, #0x005F ; constante de atraso 
delay   CBZ R3, theend ; 1 clock
        SUB R3, R3, #1 ; 1 clock
        B delay ; 3 clocks
theend 
        B loop

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
