	.section .rodata        #rodata é read-only-data



fmt:	.string "%d\n"      # fmt é o rótulo da string "%d\n" igual à passada em C para o printf.
	.text                   #text indica codigo
	.globl show             # glbl show deixa a função visivel para o linker

show:                       #inicio da função
	pushq	%rbp            #empurra o antigo frame pointer (%rbp). O %rbp fica fixo e aponta para o topo do frame reservado para a função show         
	movq	%rsp, %rbp      #coloca %rbp apontando para o frame atual. o %rsp vai descendo conforme a função reserva espaço
	subq	$32, %rsp       #reserva 32bytes na pilha para variáveis locais temporárias. São usados exatamente 32 bytes porque o x86-64 exige alinhamento de 16 bytes. 



	# i = ecx
	# for (i = 0; i < size; i++)

	movl	$0, %ecx         #está fazendo i=0

for01:

	cmpl	%esi, %ecx		#aqui está comparando size(%esi) e i(%ecx). lembra que o valor de size foi definido dentro da main01.c ? ele já está alocado no registrador esi. portanto, no show.s não precisamos alocar o size em um registrador novamente
	jge	endfor01			#se i>=size sai do for


	#se for i<size a gente entra dentro do for, que tem o printf("%d\n", v[i])     

	#nas próximas 3 linhas, só estamos os valores dos registradores das variáveis i, o ponteiro v e size em rbp (uma pilha)  pra executar fazer o printf. no x86-64 qualquer valor que o compilador quiser guardar na pilha usando movq tem tamanho 8 bytes
	movq	%rcx,  -8(%rbp)      #copia o conteudo do registrador %rcx (o valor de i) para a posição de memória -8(rbp). -8(rbp) significa: pegue o valor do registrador %rbp, subtraia 8, e acesse a memória naquele endereço. significado da linha toda: salva o valor de i (que está em %rcx) naquele slot da pilha 

	movq	%rdi, -16(%rbp) 	#copia o registrador %rdi (o ponteiro v) para -16(%rbp) na pilha. significado da linha toda: salva o ponteiro do vetor para que possamos recuperá-lo depois do printf

	movq	%rsi, -24(%rbp)		#copia o %rsi (o size) para -24(%rbp)

	

	# O 2o. parâmetro será passado primeiro para aproveitar o 'rdi'

 	# v[i]
	movq %rdi, %r8				#copia o conteudo de %rdi (ponteiro v) para %r8. o %r8 se tornou endereço base do vetor

	movslq %ecx, %r9			#converte i (32 bits) para 64 bits. agora i está em %r9. movs: move com sinal. l: origem é de 32 bits (long). q: destino é de 64 bits (quadword). fazemos isso porque os registradores de indice usados para endereçamento em 64 bits devem ser 64 bits

	imulq	$4, %r9				#multiplica i por 4 para achar o offset (offset = i * 4). aqui a gente está achando o elemento v[i], estamos multiplicando por 4 para achar esse elemento dentro da memoria, já que é um inteiro. 

	addq	%r8, %r9			#soma o endereço base com o offset. assim, vamos ver qual o endereço do elemento que estamos analisando. supondo que o offset é 5, estamos falando que querememos o endereço vase v[0] + 5 "passos", logo queremos o v[5]


	movl	(%r9), %esi		# 2o. param do printf. carrega o valor de v[i] para %esi

	movq	$fmt, %rdi		# 1o. param do printf. fmt é o label usado para armazenar a string usada pelo printf, ele aponta para "%d\n", no assembly passamos esse endereço como primeiro argumento para printf. na seção .rodata colocamos fmt como .string "%d\n" que é a string que vai ser colocada na memoria. entao fmt é o endereço de memoria onde está a string "%d\n". a linha movq $fmt, %rdi significa "coloque no registrador %rdi o endereço da string de formatação %d\n"


	movl	$0, %eax		#printf é uma função variática. funções variáticas devem informar quantos argunmentos de ponto flutuante existem. no nosso exemplo não existe, então é 0. eax é a parte mais baixa do rax, quando zeramos o eax, acaba que zeramos o 64 bits superiores. "RAX = 0x00000000  (porque escrever em EAX zera os 64 bits superiores)". lembrando que rax serve para armazenar retornos de funções

	call	printf			#chama printf

	
	#essas 3 linhas de codigo vao recuperar os valores de i, v e size
	movq	 -8(%rbp), %rcx		#pega o valor que salvou 8 bytes abaixo do rbp e coloca no registrador rcx (i)

	movq	-16(%rbp), %rdi		#pega o valor que salvou 16 bytes abaixo do rbp e coloca no registrador rdi (ponteiro v)

	movq	-24(%rbp), %rsi		#pega o valor que salvou 8 bytes abaixo do rbp e coloca no registrador rsi (size)

	incl	%ecx  # i++. é o incremento do for


	jmp	for01   #vai para o inicio do escopo do for

endfor01:		#encerra o for



	leave			#em resumo, o leave: - desfaz alocaçao do espaço locla da função - restaura o rbp antigo  - prepara a pilha para o ret

	ret				#pega da pilha o endereço de retorno e pula para lá