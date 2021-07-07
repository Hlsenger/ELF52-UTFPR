## Relatorio Laboratorio 1 Sistemas Microcontrolados

## Parte 1: Analise do exemplo 3

Inicialmente foi rodado passo a a passo usando o simulador do IAR IDE o codigo dado nu exemplo 3 e o comportamento no dissasembler é explicado a baixo para cada comando executado.

##### MOV R0, #0x55:
Comando de 32 bits que move o valor  0x55 para o registrador 0, sem afetar as flags. O comando é traduzido no disasembler para a instrução MOV.W


##### MOV R1, R0, LSL #16
Comando de 32 bits que move o valor contido em R0(no caso 0x55)  para o registrador R1 deslocado 16 bits para a esquerda, que resultada no valor 0x550000 armazenado em R1. Instrução no dissambler é dada por LSL.W

##### MOV R2, R1, LSR #8
Comando de 32 bits que move o valor contido em R1(0x550000)  para o registrador R2 deslocado 8 bits para a direita, que resultada no valor 0x5500 armazenado em R2. Instrução no dissambler é dada por LSR.W

##### MOV R3, R2, ASR #4
Comando de 32 bits que divide por 4 o valor de R2 atraves de um shift a esquerda  e armazena em R3, resultando em 0x550. Instrução no dissambler é dada por ASR.W

##### MOV R4, R3, ROR #2
Comando de 32 bits que move o valor contido em R3 para o R4 com 2 bits deslocados a direita. Esse commando é bem semelhante ao LSL, com a diferença de que os bits de menor valor são "rotacionados" para o maior valor, o que resulta no valor 0x154 . Instrução no dissambler é dada por ROR.W

##### MOV R5, R4, RRX

Commando de 32 bits que desloca o valor de R4 para a direita por 1 bit e move o valor da flag carry para o bit mais significativo e o



## Parte 2 Trocando MOV por MVN


Trocando o commando MOV por MVN em todas as linhas temos que o programa é construido e roda sem problemas, porem sem comportamento é bem diferente, ja que MVN move o valor negado do segundo parametro para o primeiro parametro. Como podemos ver em:

##### MVN R0, #0x55:

Convertendo 0x55 para binario e expandindo para 32 bits(ja que cada registrador tem 32 bits) temos 00000000 00000000 00000000 01010101, que quando aplicado o commando NOT(0x55) temos 11111111 11111111 11111111 10101010 que convertido novamente para hexadecimal temos 0xFFFFFFAA, que é exatamente o valor mostrado no simulador para R0 apos a execução deste comando.

##### MVN R1, R0, LSL #16

Apos esta instrunção temos em binario em R1 00000000 01010101 11111111 11111111, com isso podemos perceber que o shift é executado antes do NOT, pois o resultado da operação é R = NOT(R0 << 16)

##### MVN R2, R1, LSR #8

Semelhante a instrução anterior, agora temos um deslocamento a direita de 8 bits seguido por um NOT.

##### MVN R3, R2, ASR #4

Nesse caso especifico essa instrução tem o mesmo comportamento da instrução anterior, só variando o numero de bits deslocados, que nesse caso é 4 bits.

##### MVN R4, R3, ROR #2

Aqui temos um deslocamento dos 2 ultimos bits menos significativos de R3 0b0000'0000'0000'0000'0000'0101'0101'1111 que são "rotacionados" para o começo e em seguida é aplicado um NOT e movido para R4, resultando em 00111111 11111111 11111110 10101000, que bate com o valor encontrado no simulador.

##### MVN R5, R4, RRX
Como a flag carry se encontra em 0, esse comando simplsmente desloca R4 em 1 bit para a direita, armazena este bit no carry(que no caso é 0) e armazena o NOT deste deslocamento em R5, resultando em 11100000 00000000 00000000 10101011


## Conclusão

Nesse experimento aprendemos as operações basicas da IDE IAR como criar um projeto, construir um programa assembly, utilizar o simulador e o debugger. E tambem foi possivel experimentar com as diversas variações do comando MOV na arquitetura Cortex-M4.
