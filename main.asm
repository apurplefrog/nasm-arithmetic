        global _start

        section .text

print:                                      ; print function to reduce redundancy
        push rdx                            ; preserve rdx
        push rsi                            ; preserve rsi
        push rdi                            ; preserve rdi
        mov rdx, -1                         ; counter will be 0 in the first loop iteration
.length_check:                              ; find the length of the string by finding the position of a null terminator
        inc rdx                             ; increment counter
        cmp byte [rax + rdx], 0             ; compare the character at the counter's index
        jne .length_check                   ; if not 0, continue the loop
        mov rsi, rax                        ; otherwise, move the string pointer to rsi
        mov rax, 1                          ; sys_write
        mov rdi, 0                          ; std_out
        syscall                             ; call sys_write
        pop rdi                             ; reset rdi
        pop rsi                             ; reset rsi
        pop rdx                             ; reset rdx
        ret

_start:                                     ; program entry point
        mov rax, calculator_msg             ; initial message
        call print                          ; call print on initial message

get_user_input:                             ; get the expression from the user
        mov rax, 0                          ; sys_read
        mov rdi, 1                          ; std_in
        mov rsi, input_buf                  ; input_buf will contain user input
        mov rdx, 1024                       ; size of input_buffer
        syscall                             ; call sys_read

handle_user_input:                          ; handle the user input
        mov r8, rax                         ; store string length in r8
        dec r8                              ; null terminator does not matter
        mov rbx, 0                          ; set counter to 0
        mov r11, 0                          ; set first number to 0

first_number:                               ; find the second number
.char_loop:                                 ; iterate over characters in input
        mov rsi, qword [input_buf + rbx]    ; move the nth character to rsi
        and rsi, 0xff                       ; remove nonsense
        cmp rsi, 48                         ; compare value to ASCII 0
        jl .not_a_number                    ; if value is less than 0, it is not a number
        cmp rsi, 57                         ; compare value to ASCII 9
        jg .not_a_number                    ; if the value is greater than 9, it is not a number
        mov rax, 10                         ; move 10 to rax
        mul r11                             ; multiply the first number by 10
        mov r11, rax                        ; mov the first number back to r11
        add r11, rsi                        ; add the digit to the first number
        sub r11, 48                         ; remove ASCII '0'
        jmp .number_check_end               ; if value passes both checks, continue
.not_a_number:                              ; if the program has reached the operation
        mov r14, qword [input_buf + rbx]    ; move the nth character to r14
        and r14, 0xff                       ; set the index of the operator to the counter value
        jmp second_number                   ; time to work on the second number!
.number_check_end:                          ; after all the checks
        inc rbx                             ; increment counter
        jmp .char_loop                      ; continue the loop

second_number:                              ; find the second number
        inc rbx                             ; increment the char pointer
        mov r12, 0                          ; set the second number to 0
.second_number_loop:                        ; loop over the digits of the second number
        mov rsi, qword [input_buf + rbx]    ; move the nth character to rsi
        and rsi, 0xff                       ; remove nonsense
        mov rax, 10                         ; move 10 to rax
        mul r12                             ; multiply the second number by 10
        mov r12, rax                        ; mov the second number back to r12
        add r12, rsi                        ; add the digit to the second number
        sub r12, 48                         ; remove ASCII '0'
        inc rbx                             ; increment counter
        cmp rbx, r8                         ; compare the counter with the string length
        jne .second_number_loop             ; if they're not equal, continue the loop

evaluate_expression:                        ; evaluate the expression
        mov rsi, r11                        ; move the first number to rsi
        cmp r14, 43                         ; if the operation is addition,
        je .add                             ; jump to .add
        cmp r14, 45                         ; if the operation is subtraction,
        je .subtract                        ; jump to .subtract
        cmp r14, 42                         ; if the operation is multiplication,
        je .multiply                        ; jump to .multiply
        cmp r14, 47                         ; if the operation is division,
        je .divide                          ; jump to .divide
.add:                                       ; to add the two numbers
        add rsi, r12                        ; use the add operator
        jmp print_results                   ; and print the results
.subtract:                                  ; to subtract the two numbers
        sub rsi, r12                        ; use the sub operator
        jmp print_results                   ; and print the results
.multiply:                                  ; to multiply the two numbers
        mov rax, rsi                        ; first, move the first number to rax
        mul r12                             ; and multiply it by the second number
        mov rsi, rax                        ; move the number back to rsi
        jmp print_results                   ; and print the results
.divide:                                    ; to divide the two numbers
        mov rax, rsi                        ; first, move the first number to rax
        div r12                             ; divide it by the second number
        mov rsi, rax                        ; move the number back to rsi
        jmp print_results                   ; and print the results

print_results:                              ; now, print the result
        push 0                              ; add dummy value to stack
        mov rbx, 0                          ; set counter to 0
        mov rax, rsi                        ; move value into rax
.char_loop:                                 ; loop over the numbers
        mov rdx, 0                          ; set remainder to 0
        mov rcx, 10                         ; divide by 10
        div rcx                             ; divide
        add rdx, 48                         ; int -> char
        push rdx                            ; push char
        cmp rax, 0                          ; compare value to 0
        jne .char_loop                      ; if not equal, continue
.print_loop:                                ; print the characters now
        mov rax, rsp                        ; move a pointer to the top of the stack to rax
        call print                          ; and print the character
        pop rcx                             ; pop the number into a dummy register
        cmp rax, 0                          ; if the result is now 0, we're done
        je exit                             ; and we can exit the program
        jmp .print_loop                     ; otherwise, continue the loop

exit:                                       ; exit the program properly
        mov rax, newline                    ; move a newline string pointer to rax
        call print                          ; print newline
        mov rax, 60                         ; sys_exit
        xor rdi, rdi                        ; error code
        syscall                             ; call sys_exit

        section .rodata
calculator_msg:
        db "Enter your expression:", 10, 0  ; initial string
newline:
        db 10, 0                            ; newline

        section .bss
input_buf:
        resb 1024                           ; input buffer with 1024 bytes
