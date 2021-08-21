        PUBLIC  __iar_program_start
        EXTERN  __vector_table
        EXTERN UART_enable,GPIO_enable,GPIO_special,GPIO_select,UART_config

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608
SYSCTL_PRGPIO		EQU     0x0A08
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
; System Control bit definitions
PORTA_BIT               EQU     000000000000001b ; bit  0 = Port A
PORTF_BIT               EQU     000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     001000000000000b ; bit 12 = Port N
UART0_BIT               EQU     00000001b        ; bit  0 = UART 0

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400
GPIO_IS                 EQU     0x0404
GPIO_IBE                EQU     0x0408
GPIO_IEV                EQU     0x040C
GPIO_IM                 EQU     0x0410
GPIO_RIS                EQU     0x0414
GPIO_MIS                EQU     0x0418
GPIO_ICR                EQU     0x041C
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_PCTL               EQU     0x052C

; UART definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8
;UART bit definitions
TXFE_BIT                EQU     10000000b ; TX FIFO full
RXFF_BIT                EQU     01000000b ; RX FIFO empty
BUSY_BIT                EQU     00001000b ; Busy


; PROGRAMA PRINCIPAL

__iar_program_start
        
main:   

;======== Inicializacao dos perifericos ========
        MOV R2, #(UART0_BIT)
	BL UART_enable ; habilita clock do UART0

        MOV R2, #(PORTA_BIT)
	BL GPIO_enable ; habilita clock do GPIOA
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b ; bits 0 e 1 como especiais
        BL GPIO_special
        
        ;Seta os pinos A0 e A1 para funçãao alternativa(UART RX e TX)
	MOV R1, #0xFF 
        MOV R2, #0x11
        BL GPIO_select

	LDR R0, =UART_PORT0_BASE
        BL UART_config ; configura periférico UART0
        
;==============Programa Principal ==========================     
        MOVS R4, #0 ;Mantem o estado atual da operacao, 0 = Primeiro digito, 1 = segundo digito
        MOVS R5, #0 ;Conta o numero de digitos lido no estado

loop:
        LDR R3, =UART_PORT0_BASE
wrx:    
        LDR R2, [R3, #UART_FR] ; status da UART
        TST R2, #RXFF_BIT ; receptor cheio?
        BEQ wrx
        LDR R0, [R3] ; lê do registrador de dados da UART0 (recebe)
        BL testa_char
        CMP R1, #0
        BLE wrx
        
        
        MOVS R9, R0 ;Mantem uma copia do digito no R9
        
       
        ;;Se R4=0 vai para estado 0, caso contrario estado 1
        CMP R4,#0
        BNE digito2
        
        ;Estados possiveis
digito1:

        BL testa_char
        CMP R1, #5
        BEQ digito1_num
        CMP R1, #4
        BLE digito1_operador
        B loop
        
digito1_num:
        CMP R5, #3 ;Limita a entrada a 3 caracteres de acordo com a especificacao
        BGE loop
        BL ASCII_to_int
        PUSH {R0}
        ADDS R5,#1
        
        BL uart0_write_char  
        B loop
      
digito1_operador:
        CMP R5, #0 ;Se o primeiro caracter é um operador, ignore
        BEQ loop
        
        MOVS R6,R1;Guarda a operacao a no R6 e muda de estado

        MOVS R0,R5
        BL converte_numero
        MOV R8, R1
        MOV R5, #0
         
        MOVS R4,#1 ;Troca de estado


        BL uart0_write_char

        B loop
        
digito2:
        BL testa_char
        CMP R1, #5
        BEQ digito2_num
        CMP R1, #6
        BEQ digito2_operador
        B loop
        
digito2_num:
        CMP R5, #3 ;Limita a entrada a 3 caracteres de acordo com a especificacao
        BGE loop
        
        BL ASCII_to_int
        PUSH {R0}
        ADDS R5,#1
        
        
        BL uart0_write_char
        
        B loop
        
digito2_operador:  
        CMP R5, #0 ;Se o primeiro caracter é um operador, ignore
        BEQ loop
        
        MOVS R0,R5
        BL converte_numero
        
        
        
         ;Testa se ouve divisão por 0
        CMP R6,#4 ; Verifica se é uma divisão
        BNE digito2_operador_operacao
        CMP R1,#0 ; Verifica se o divisor é 0
        BNE digito2_operador_operacao
        
        
        ;Chama a subrotina que escreve "DIV0" no UART0
        PUSH {R0-R3}
        LDR R0, =UART_PORT0_BASE
        LDR R1,=ROMSTRING1 ;Ponteiro para o primeiro caractere da string de retorno
        MOVS R2,#5 ;;Numero de caracteres na string
        BL UART_write_string
        POP {R0-R3}
        B digito2_operador_fim
        
        
       
        
digito2_operador_operacao:
        CMP R6,#1 ;Soma
        IT EQ
          ADDEQ R8,R1
          
        CMP R6,#2 ;Subtracao
        IT EQ
          SUBEQ R8,R1
          
        CMP R6,#3 ;Multiplicacao
        IT EQ
          MULEQ R8,R1
        
        CMP R6,#4 ;Divisao
        IT EQ
          SDIVEQ R8,R1
          
        BL uart0_write_char
        MOV R0,R8
        BL int_to_ASCII
        
      
  
      
        
digito2_operador_fim:      
        ;Transmite o /r/n
        MOV R0,#0x0D
        BL uart0_write
        MOV R0,#0x0A
        BL uart0_write
 
        MOVS R8,#0 ;;Reseta registradores
        MOVS R5,#0
        MOVS R4,#0 ;Troca de estado


        
        
        B loop


; SUB-ROTINAS

;----------
;Transmite via UART0 o valor em R0(no maximo 8 bits)
uart0_write:
        PUSH {R1,R2}
        
        
        LDR R1, =UART_PORT0_BASE
        
uart0_write_loop:
        LDR R2, [R1, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT ; transmissor vazio?
        BEQ uart0_write_loop
        STR R0, [R1] ; escreve no registrador de dados da UART0 (transmite)
        
        POP {R1,R2}
        BX LR
        
;Transmite via UART0 o valor em R9(no maximo 8 bits)
uart0_write_char:
        PUSH {R1,R2}
        
        
        LDR R1, =UART_PORT0_BASE
        
uart0_write_char_loop:
        LDR R2, [R1, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT ; transmissor vazio?
        BEQ uart0_write_char_loop
        STR R9, [R1] ; escreve no registrador de dados da UART0 (transmite)
        
        POP {R1,R2}
        BX LR



;Converte o valor no topo da pilha com R0 elementos em um inteiro em R1
converte_numero:
        MOVS R1,#0
        MOVS R3,#1
        MOV R7,#10
converte_numero_loop:
        POP {R2}
        MUL R2,R2,R3
        MUL R3,R3,R7
        
        ADDS R1,R2
        SUBS R0,#1
        BNE converte_numero_loop
        
        BX LR
        

 
;Testa se R0 e um numero ou um operador aritimetico, retorna R1: 1 - '+", 2- "-", 3 -"*" , 4 -"/",  5- numero, 6 -  '=" , 0 -Não operador 
testa_char:
        MOVS R1,#0
        
       
        
        CMP R0, #0x2B; Testa '+'
        IT EQ
          MOVSEQ R1, #1
          
        CMP R0, #0x2D; Testa '-'
        IT EQ
          MOVSEQ R1, #2
          
        CMP R0, #0x2A; Testa '*'
        IT EQ
          MOVSEQ R1, #3
        
        CMP R0, #0x2F; Testa '/'
        IT EQ
          MOVSEQ R1, #4
          
        CMP R0, #0x3D; Testa '='
        IT EQ
          MOVSEQ R1, #6
        
        CBNZ R1, fim_testa_char
      
        
        ;Testa se é um numero
        PUSH {R0}
        MOVS R1,#0
        SUBS R0, #0x30
        BLO fim_testa_char
        CMP R0, #9; Checa se o caractere ASCII esta entre 0x30(0) e 0x57(9)
        IT LE
          MOVLE R1, #5
        POP {R0}
        BLE fim_testa_char
        
 
fim_testa_char:

      BX LR
        


;Funcao que converte um ascii em um inteiro
;R0=Valor do caracter em ASCII, retornado em valor numerico
ASCII_to_int:
        SUBS R0, #0x30
        BX LR




; Converte inteiro em R0 para ASCII e envia via UART0
int_to_ASCII:
        PUSH {R4-R8}
        MOV R4,R0
        MOV R5,#10 ;Guarda a constante 10
        MOV R7,#1 ;Guarda o maior multiplo de 10 do numero
        MOV R6,#0 ;Conta o numero de algarismos no numero
       

       
        CMP R0, #0
        BGE int_to_ASCII_loop1
          
        
        ;Imprime um - na frente do resultado se for negativo
        MOV32 R8,#-1
        MUL R0,R8
        PUSH {R0,LR}
        MOV R0,#0x2D
        BL uart0_write
        POP {R0,LR}
     
int_to_ASCII_loop1: ;Divide ate chegar em um valor menor que para contar o numero de algarismos
        ADDS R6,#1
        MUL R7,R5
        SDIV R4,R5
        CMP R4, #0
        BNE int_to_ASCII_loop1
        
             
        MOV R4,R0
int_to_ASCII_loop2:
        SDIV R7,R5
        SDIV R8,R4,R7
        
        MOV R0,R8
        ADD R0,#0x30
       
        PUSH {LR}
        BL uart0_write
        POP {LR}
        
        MUL R8,R8,R7
        SUB R4,R8

        CMP R7, #1
        BNE int_to_ASCII_loop2
        
        POP {R4-R8}
        BX LR



; UART_write_string: envia a string iniciado no enderedo R0 com R1 caracteres
;R0 = Endereco do UART utilizado, R1 = Ponteiro do primeiro caracter da string, R2 = numero de caracteres
; Destroi: R3
UART_write_string:
        PUSH {R4,R5}
        MOVS R4,#0; Reseta o contador de caracteres
        
UART_write_string_loop:       
        LDR R3, [R0, #UART_FR] ; status da UART
        TST R3, #TXFE_BIT ; transmissor vazio?
        BEQ UART_write_string_loop
        
        LDR R5,[R1,R4]
        STR R5, [R0] ; escreve no registrador de dados da UART0 (transmite)

        ADDS R4,R4,#1
        
        CMP R4,R2 ; Se o numero de caracteres enviados é igual o da string, encerra o loop
        BNE UART_write_string_loop
        
        
        POP {R4,R5}
        BX LR
        
        
        SECTION .rodata:CONST(2)
        DATA
ROMSTRING1   DC8  "=DIV0"  




        END