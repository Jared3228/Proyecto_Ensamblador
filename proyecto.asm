; ------------------------------------------------------------
; Proyecto Módulo 1 - Visor de Memoria
; Lenguajes de Interfaz (SCC-1014)
;
; Descripción: Recorre un arreglo de 10 elementos y muestra
; su dirección y valor en hexadecimal.
; ------------------------------------------------------------
extrn GetStdHandle: proc
extrn WriteConsoleA: proc

.data
 ; ---- Arreglo de 10 elementos (modifica estos valores) ----
 arreglo DQ 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
 ; ------------------------------------------------------------
 newline DB 13, 10, 0 ; CR + LF + null
 buffer DB 64 DUP (0) ; Buffer para construir la salida Nota: Se agrando el tamaño
 hex_chars DB '0123456789ABCDEF' ; Tabla de conversión a hex
 escritos DQ 0;
.code
; ------------------------------------------------------------
; Función: print_hex_qword
; Imprime un QWord (64 bits) en hexadecimal con 16 dígitos
; Entrada: RAX = valor a imprimir
; RDI = puntero al buffer (donde escribir)
; Salida: RDI apunta al final del string (después del último carácter)
; ------------------------------------------------------------
print_hex_qword proc
 push rbx
 push rcx
 push rdx
 ; Recorremos los 16 dígitos hexadecimales (64 bits / 4 bits por dígito)
 mov rcx, 16 ; Contador de dígitos
 add rdi, 15 ; Empezamos desde el final del buffer (16 dígitos)
 mov rbx, 0Fh ; Máscara para los 4 bits bajos
hex_loop:
 mov rdx, rax
 and rdx, rbx ; Extraer los 4 bits bajos
 movzx rdx, byte ptr [hex_chars + rdx] ; Obtener el carácter hex
 mov [rdi], dl ; Almacenar en el buffer (de atrás hacia adelante)
 dec rdi ; Moverse hacia la izquierda
 shr rax, 4 ; Desplazar a la derecha 4 bits
 loop hex_loop
 ; Restaurar puntero (sumamos 1 porque decrementamos una vez de más)
 add rdi, 1
 pop rdx
 pop rcx
 pop rbx
 ret
print_hex_qword endp
; ------------------------------------------------------------
; Función: print_string
; Imprime una cadena usando la interrupción de consola
; Entrada: RDI = puntero a la cadena terminada en 0
; ------------------------------------------------------------
print_string proc
 push rbx ; Importante proteger el rbx porque la primera vez crasheo por guardar el handle ahi
 push rcx
 push rdx
 push r8
 push r9
 ; Calcular la longitud de la cadena
 mov rcx, -1
 xor al, al
 repne scasb ; Encontrar el null (longitud en RCX)
 not rcx
 dec rcx ; RCX = longitud
 ; Ahora RDI apunta al final, necesitamos restaurarlo
 sub rdi, rcx
 sub rdi, 1

 ; ------------------------------------------------------------
 push rcx ; Protegemos la longitud porque yo mismo la destrui abajo 

 ; Obtemos el Handle de la consola y como es una funcion externa abrimos un shadow space temporal
 sub rsp, 28h
 mov rcx, -11
 call GetStdHandle
 add rsp, 28h
 mov rbx, rax ; Guardar Handle

 pop rcx ; La recuperamos 
; Preparamos los parametros para WriteConsoleA

 mov r8, rcx ; Movemos la longitud
 mov rdx, rdi ; El puntero del mensaje
 mov rcx, rbx ; Handle de salida
 lea r9, escritos 

; Llamamos el writeconsole con su propio shadow space
 sub rsp, 28h
 mov qword ptr [rsp + 20h], 0 ; lpReserved = NULL
 call WriteConsoleA
 add rsp, 28h
 ; ------------------------------------------------------------
 pop r9
 pop r8
 pop rdx
 pop rcx
 pop rbx ; Lo restauramos (IMPORTANTISIMO RECORDAR QUE LOS POP FUNCIONA CON LIFO) Media hora perdida 
 ret
print_string endp
; ------------------------------------------------------------
; Función principal
; ------------------------------------------------------------
main proc
 sub rsp, 28h
 ; ------------------------------------------------------------
 ; 1. Recorrer el arreglo
 ; ------------------------------------------------------------
 lea rbx, arreglo ; RBX = puntero al inicio del arreglo
 mov rcx, 10 ; RCX = contador (10 elementos)
recorrer_arreglo:
 ; ------------------------------------------------------------
 ; 1. Construimos la primera parte del mensaje "Direccion: " byte por byte
 mov byte ptr [buffer + 0], 'D'
 mov byte ptr [buffer + 1], 'i'
 mov byte ptr [buffer + 2], 'r'
 mov byte ptr [buffer + 3], 'e'
 mov byte ptr [buffer + 4], 'c'
 mov byte ptr [buffer + 5], 'c'
 mov byte ptr [buffer + 6], 'i'
 mov byte ptr [buffer + 7], 'o'
 mov byte ptr [buffer + 8], 'n'
 mov byte ptr [buffer + 9], ':'
 mov byte ptr [buffer + 10], ' '

; 2. Metemos el valor a hexadecimal despues de los 6 bytes que ocupamos ya
 mov rax, rbx ; Copiar la direccion de memoria a rax
 lea rdi, [buffer + 11] ; rdi apunta al inicio despues de "Direccion: "
 call print_hex_qword ; Esto escribira 16 bytes

; 3. Construimos el mensaje " Valor: " desde el byte 27

 mov byte ptr [buffer + 27], ' '
 mov byte ptr [buffer + 28], 'V'
 mov byte ptr [buffer + 29], 'a'
 mov byte ptr [buffer + 30], 'l'
 mov byte ptr [buffer + 31], 'o'
 mov byte ptr [buffer + 32], 'r'
 mov byte ptr [buffer + 33], ':'
 mov byte ptr [buffer + 34], ' '
;4. Mandamos a llamar el valor hexadecimal de direccion despues del byte 35
 mov rax, [rbx] ; Copiar el valor que tiene rbx
 lea rdi, [buffer + 35]
 call print_hex_qword ; Esto escribira 16 bytes hasta el 51
 ; 5. Saltos de linea
 mov byte ptr [buffer + 51], 13 ; CR
 mov byte ptr [buffer + 52], 10 ; LF
 mov byte ptr [buffer + 53], 0  ; Null terminador 

 ;6. Imprimir
 lea rdi, buffer
 push rcx
 call print_string
 pop rcx ; La funcion la regresaba corrupta aunque tuviera el push y pop dentro de la propia funcion
 ; ------------------------------------------------------------
 ; Avanzar al siguiente elemento
 add rbx, 8 ; Siguiente elemento (8 bytes)
 dec rcx ; Lo decrementamos manualmente 
 jnz recorrer_arreglo ; Loop ya no funcionaba porque se pasa 74 bytes de los 128 que deja 
 ; ------------------------------------------------------------
 ; 3. Terminar
 ; ------------------------------------------------------------
 xor eax, eax
 add rsp, 28h
 ret
main endp
end