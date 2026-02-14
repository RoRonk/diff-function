.data
lines:
    .byte 1
    .byte 1

.text
diff_location:  .asciz "%dc%d\n< "
changed_to:     .asciz "\n---\n> "
char_output:    .asciz "%c"
neat_end:       .asciz "\n\n"

// format_string:      .asciz  "Hi, this IS a testfile.\n\nTestfile 1 to be precise.\n\nWe are the same.\nThis is the fourthL.\nLastline."
// format_string_2:    .asciz  "Hi, this is A testfile.\nTestfile 2 to be precise.\nWe are the same.\nThIS is the fourthline.\nLastLine."

old:    .asciz  "this is a random sentence, pretty good right???\n\nyess sure"
new:    .asciz  "this is a randm sentence, pretty GOOD right???\nyess sure"

.global main

main:
    # prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

    movq $old, %rdx
    movq $new, %rcx

    call diff

    # epilogue
	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

diff:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    pushq %rdi                  # parameter count
    pushq %rsi                  # vextor pointer BS table

    # callee
    pushq %rbx			        # second character pointer
	pushq %r12			        # line counter
	pushq %r13			        # first character pointer
	pushq %r14			        # old text
    pushq %r15                  # new text
    sub $8, %rsp                # to align the stack
    
    movq %rdx, %r14
    movq %rcx, %r15

    // so here we check first parameter. 
    // make the check_which_parameter method a loop through parameter method

    movq $0, %r13               # initialize r13 as character pointer 
    movq $0, %rbx               # initialize rbs as 2nd character counter
    movq $lines, %r12               # initialize r12 as \n counter, we start at line 1



    // each diff option will now have the same diff loop, but they cant intersect.
    // we can either duplicate code or do something else.
diff_loop:
    movb (%r14, %r13), %r8b	    # grabs the (r13)th byte (ASCII-char) to r8
    movb (%r15, %rbx), %r9b	    # grabs the (rbx)th byte (ASCII-char) to r9

    cmpb $0, %r8b               # see if we have already reached the end
    je epilogue                 # we already know they are the same, so we don't care

    cmpb $0, %r9b               # see if we have already reached the end
    je epilogue                 # we already know they are the same, so we don't care

    cmpb %r9b, %r8b             # compare if they are the same
    jne check_what_option

    incq %r13
    incq %rbx

    cmpb $'\n', %r8b                # then we have gone through a whole line, so we increment line counter
    je increment_line_counter
    jmp diff_loop

    increment_line_counter:
        movq $0, %rax
        addq $1, (%r12, %rax)
        incq %rax
        addq $1, (%r12, %rax)
        jmp diff_loop

print_diff:
    # print the diff start

	movq $0, %rsi					# empty %RSI to put the char in

    # e.g.: 2c2\n< 
    movq $0, %rax					# no vector register
    movq $0, %rdx                   # move $0 into rdx
	movq $diff_location, %rdi		# move output_str to rdi
    movq $0, %rax					# move $0 into rax
	movb (%r12, %rax), %sil	        # move the line counter into rsi
    incq %rax					    # increment rax
    movb (%r12, %rax), %dl          # also move same line for the second character
    call printf

    cmpb $1, (%r12)
    je start_print

find_line_start_1:
    # loop back until you find /n character for the old string
    decq %r13
    cmpb $'\n', (%r14, %r13)           # if it is /n character, we have then reached the ebd if the last line
    je find_line_start_2
    jmp find_line_start_1

find_line_start_2:
    # loop back until you find /n character for second string
    decq %rbx
    cmpb $'\n', (%r15, %rbx)           # if it is /n character, we have then reached the ebd if the last line
    je start_later
    jmp find_line_start_2

start_print:
    # since we are still on line 1, we need to go back to byte 0 and print from that till line 1

    movq $0, %r13
    movq $0, %rbx

    jmp print_old

    start_later:
        incq %r13                   # to get the first character after the \n character
        incq %rbx                   # to get the first character after the \n character

    print_old:
        movb (%r14, %r13), %sil	    # grabs the (rcx)th byte (ASCII-char) to r8
        cmpb $'\n', %sil            # if it is /n character, we have almost finished the whole line so we go to print the changed line
        je changed_to_print
        cmpb $0, %sil               # if it is /n character, we have almost finished the whole line so we go to print the changed line
        je changed_to_print

        movq $0, %rax               # no vector registers
        movq $char_output, %rdi
        call printf

        incq %r13
        jmp print_old
    
    changed_to_print:
        movq $0, %rax					# no vector register
	    movq $changed_to, %rdi		    # move output_str to %RDI
        call printf

    print_new:
        movb (%r15, %rbx), %sil	        # grabs the (rcx)th byte (ASCII-char) to r8
        cmpb $'\n', %sil                # if it is /n character, we have almost finished the whole line so we go to print end
        je print_end
        cmpb $0, %sil                   # if it is 0 character, we have almost finished the whole line so we go to print the changed line
        je print_end

        movq $0, %rax                   # no vector registers
	    movq $char_output, %rdi		        # move output_str to %RDI
        call printf

        incq %rbx
        jmp print_new

print_end:
    # print one more time and then pop rcx back

    incq %r13
    incq %rbx

    # Robin being a perfectionist and having to make things look pretty
    push %rsi
    push %rsi
    
    movq $neat_end, %rdi
    movq $0, %rax                   # print \n character for the last time
    call printf

    # pop the character back
    pop %rsi
    pop %rsi
    # End of Robin being a perfectionist and having to make things look pretty

    cmpb $0, %sil            # if it is /n character, we have almost finished the whole line so we go to print the changed line
    je epilogue

    movq $0, %rax
    addq $1, (%r12, %rax)
    incq %rax
    addq $1, (%r12, %rax)
    jmp diff_loop

epilogue:
    # callee popped back
    add $24, %rsp        # add 8, quz we subbed 8 at the start 
    popq %r15			# callee saved register so we pop back into r15
    popq %r14			# callee saved register so we pop back into r14
	popq %r13			# callee saved register so we pop back into r13
    popq %r12			# callee saved register so we pop back into r12
	popq %rbx			# callee saved register so we pop back into rbx

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

B_diff:
# ignore /n characters if not at the end of string

    // Check if the old file has a blankline
    cmpb $'\n', (%r14, %r13)    # check if curr char of old file is '\n'
    je B_check_prev_char_1      # jump to check previous char

    // Check if the new file has a blankline
    cmpb $'\n', (%r15, %rbx)    # check if curr char of new file is 'n'
    je B_check_prev_char_2      # jump to check previous char

    jmp check_if_i_diff         # check if we need to do i_diff

    B_check_prev_char_1:
        movq %r13, %rax             # move char pointer value to rax
        decq %rax                   # decrement rax
        cmpb $'\n', (%r14, %rax)    # check if prev char of old file is '\n'
        jne check_if_i_diff         # jump check_if_i_diff

        // now we have an blank line so we incr the linecounter
        movq $0, %rax               # move $0 to rax, get old file linecounter
        addq $1, (%r12, %rax)       # add 1 to linecounter of old file

        // incr char pointer old file
        incq %r13                   # incr r13, go back to curr char
        jmp diff_loop               # loop to next char

    B_check_prev_char_2:
        movq %rbx, %rax             # move char pointer value to rax
        decq %rax                   # decrement rax
        cmpb $'\n', (%r14, %rax)    # check if prev char of new file is '\n'
        jne check_if_i_diff         # jump check_if_i_diff

        // now we have an blank line so we incr the linecounter
        movq $1, %rax               # move $1 to rax, get new file linecounter
        addq $1, (%r12, %rax)       # add 1 to linecounter of new file
        // incr char pointer new file
        incq %rbx
        jmp diff_loop

    check_if_i_diff:
        // check if we need to use the general diff code or i_diff code
        jmp look_for_i_option_setup

i_diff:
# ignore cases
    cmpb $65, %r8b
    jl check_if_B_diff
    cmpb $65, %r9b
    jl check_if_B_diff

    cmpb $90, %r8b
    jle make_lower_r8
    cmpb $90, %r9b
    jle make_lower_r9

    jmp print_diff
    
    make_lower_r8:
        addb $32, %r8b           # since r8b is smaller, we convert it to 'lower case' for a second comparison

        cmpb %r9b, %r8b          # second comparison
        jne check_if_B_diff      # if still not equal, then it is not a case difference

        incq %r13                # increment the character counters
        incq %rbx

        subb $32, %r8b
        cmpb $'\n', %r8b                # then we have gone through a whole line, so we increment line counter
        je increment_line_counter
        jmp diff_loop
                 
    make_lower_r9:
        addb $32, %r9b           # since r8b is smaller, we convert it to 'lower case' for a second comparison

        cmpb %r9b, %r8b          # second comparison
        jne check_if_B_diff      # if still not equal, then it is not a case difference

        incq %r13                # increment the character counters
        incq %rbx

        subb $32, %r9b
        cmpb $'\n', %r9b                # then we have gone through a whole line, so we increment line counter
        je increment_line_counter
        jmp diff_loop

    check_if_B_diff:
        // not neccessary just jump to print_diff
        // because we first do -B and then check for -i
        jmp print_diff 

check_what_option:
    // besides the fist comparison, we would not be using the amount of arguments in a compare. fucks things up

    # check if 1. yes? jmp print_diff
    cmpq $1, -8(%rbp)
    je print_diff

    movq $0, %rdi                   # set param counter to 0

    look_for_B_option:
    # in case bullshit parameters?
        incq %rdi                   # increment param counter
        cmpq -8(%rbp), %rdi         # check if we have run through all cmd line params
        jge look_for_i_option_setup # we have checked for -B, there are could be -i

        movq -16(%rbp), %rax        # move rsi to rax (pointer to array of pointers (memory addresses))
        movq (%rax, %rdi, 8), %rax  # move string pointer of parameter to rax
        cmpb $'-', (%rax)           # check if it is an option
        jne look_for_B_option       # loop and get next param if not
        
        incq %rax                   # get second char
        cmpb $'B', (%rax)           # check it is the i option
        jne look_for_B_option       # loop and get next param if not

        incq %rax                   # get third char
        cmpb $0, (%rax)             # check it is the end of the string
        je B_diff                   # jump if it is only "-B"

        jmp look_for_B_option

    look_for_i_option_setup:
        movq $0, %rdi               # set param counter to 0

    look_for_i_option:
    # in case bullshit parameters?
        incq %rdi                   # increment param counter
        cmpq -8(%rbp), %rdi         # check if we have run through all cmd line params
        jge print_diff              # we have checked for -i & -B, there are none, so jump regular diff

        movq -16(%rbp), %rax        # move rsi to rax (pointer to array of pointers (memory addresses))
        movq (%rax, %rdi, 8), %rax  # move string pointer of parameter to rax
        cmpb $'-', (%rax)           # check if it is an option
        jne look_for_i_option       # loop and get next para if not
        
        incq %rax                   # get second char
        cmpb $'i', (%rax)           # check it is the i option
        jne look_for_i_option       # loop and get next param if not

        incq %rax                   # get third char
        cmpb $0, (%rax)             # check it is the end of the string
        je i_diff                   # jump if it is only "-i"

        jmp look_for_i_option       # loop and get next param
