        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

SYSCTL_RCGCGPIO_R               EQU     0x400FE608
SYSCTL_PRGPIO_R		        EQU     0x400FEA08

PORTEN_BIT                      EQU     1000100100000b ; Habilita porta F, N e J


GPIO_PORTN_DATA_MASKED_R    	EQU     0x40064000
GPIO_PORTN_DATA_R    	        EQU     0x400643FC
GPIO_PORTN_DIR_R     	        EQU     0x40064400
GPIO_PORTN_DEN_R     	        EQU     0x4006451C

GPIO_PORTF_DATA_MASKED_R    	EQU     0x4005D000
GPIO_PORTF_DATA_R    	        EQU     0x4005D3FC
GPIO_PORTF_DIR_R     	        EQU     0x4005D400
GPIO_PORTF_DEN_R     	        EQU     0x4005D51C

GPIO_PORTJ_DATA_MASKED_R    	EQU     0x40060000
GPIO_PORTJ_DATA_R    	        EQU     0x400603FC
GPIO_PORTJ_DIR_R     	        EQU     0x40060400
GPIO_PORTJ_DEN_R     	        EQU     0x4006051C
GPIO_PORTJ_PUR_R                EQU     0x40060510



initgpio    
            MOV R2, #PORTEN_BIT
            LDR R0, =SYSCTL_RCGCGPIO_R
            LDR R1, [R0] ; leitura do estado anterior
            ORR R1, R2 ; habilita port F e N
            STR R1, [R0] ; escrita do novo estado

            LDR R0, =SYSCTL_PRGPIO_R
sr0_wait	
          LDR R2, [R0] ; leitura do estado atual
          TEQ R1, R2 ; clock do port N habilitado?
          BNE sr0_wait ; caso negativo, aguarda


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

          ;;Configura porta J
          MOV R2, #00010011b ; Habilita bit 0(B1) e bit 1(B2)


        
          LDR R0, =GPIO_PORTJ_DIR_R
          LDR R1, [R0]
          BIC R1, R2   ;Seta modo input nos botoes
          STR R1, [R0]
          
         
          LDR R0, =GPIO_PORTJ_DEN_R
          LDR R1, [R0]
          ORR R1, R2  ;Habilita funcao digital
          STR R1, [R0]
          
          
          LDR R0, =GPIO_PORTJ_PUR_R
          LDR R1, [R0]
          ORR R1, R2 ; Habilita modo Pull-up
          STR R1, [R0]
          
          

          BX LR

update_leds ;;Atualiza os leds baseado no contador no R0
        PUSH {R1-R3}
        
        LDR R1, = GPIO_PORTF_DATA_MASKED_R ;Offset porta F
        LDR R2, = GPIO_PORTN_DATA_MASKED_R ;Endereco porta N

        ;Testa Led D4
        AND R3, R0,#0001b
        STR R3, [R1,#0000100b]
        
        ;Testa Led D3
        AND R3, R0,#0010b
        LSL R3, R3, #3
        STR R3, [R1,#1000000b]
        
        ;Testa Led D1
        AND R3, R0,#0100b
        LSR R3, R3, #2
        STR R3, [R2,#0000100b]
        
        ;Testa Led D1
        AND R3, R0,#1000b
        LSR R3, R3, #2
        STR R3, [R2,#0001000b]
        
        POP {R1-R3}
        BX LR


delay_debounce
     PUSH {R0}
     MOVT R0, #0x0005 ; Pequeno delay pra prevenir o bouncing
sr2_loop
     CBZ R0, sr2_end
     SUB R0, R0, #1
     B sr2_loop 
     
sr2_end
     POP {R0}
     BX LR


__iar_program_start
        
main    
        BL initgpio ;;Inicializa portas GPIO F e N
 	
        MOV R0, #0 ;Zera contador
        
loop	
        BL update_leds
        
        LDR R7, = GPIO_PORTJ_DATA_MASKED_R 
        
        LDR R2, [R7,#1100b] ;;Estado atual dos botoes
        MOVS R3,R2

notpressed_state
        MOVS R2, R3 ;;Atualiza o ultimo estado conhecido dos botoes
        BL delay_debounce
notpressed_state_loop
        LDR R3, [R7,#1100b]
        CMP R2,R3
        BNE pressed_state
        B notpressed_state_loop

pressed_state
        MOV R2, R3 ;;Atualiza o ultimo estado conhecido dos botoes
        CMP R2,#0x2
        ITE HS
          ADDHS R0,#1 ;;Soma 1 ao contador
          SUBLO R0,#1 ;;Subtrai um do contador
        
        CMP R0,#16 ;;Reseta o contador se se valor foi superior a 15
        IT HS
          MOVHS R0,#0
        
        BL update_leds
        BL delay_debounce
        
pressed_state_loop
        LDR R3, [R7,#1100b]
        CMP R2,R3
        BNE notpressed_state
        B pressed_state_loop
      
        
end_loop
        B end_loop

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
