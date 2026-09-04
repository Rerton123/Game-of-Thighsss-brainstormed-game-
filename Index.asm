bits 16; 16 bit mode
org 0x7c00; |0x7c00|memory adresas nuo kur prasides mano kodas - memory
Start:
    xor bx,bx
    mov ds,bx
    mov [boot_drive], dl
    mov word [seed],ax

    ;~32kb space, used 11kb

    xor ax,ax; Loadina grafikas is hard drive y ram [kas yra nuo 512 byte]
    mov es, ax      ; ES:BX, sektorius rame kur
    mov ah, 02h     ; BIOS: skaityti sektorius is hard drive
    mov al, 63       ; Kiek sekturiu skaityti
    mov ch, 0       ; cylinder
    mov cl, 2       ; sectorius  kuris, nuo 1?
    mov dh, 0       ; head ?
    mov dl, [boot_drive]     ; drive 80h = first hard disk| boot
    mov bx, 0x7E00     ; ES:BX = kur data rame atsiras, sektorius 0x7c00 ir nuo jo 512 byto
    int 13h

    mov al, 34h; PIT intterupts hlt at 1,193,182 Hz
    out 43h, al
    mov ax, 31930; we give 1193 so it would slow down speed of pit by 1193 times
    out 40h, al          
    mov al, ah
    out 40h, al  


    mov ah,0
    mov al,13h
    int 0x10; video mode 13h

    xor di,di
    mov ax,0xA000
    mov es,ax

    MouseIni:
        .wait:
            in   al, 64h ; gauna informacija is I/O port 64h | in -> skaityti byte is tam tinkamos vietos
            test al, 10b ; jeigu byte 1 yra, tada laukia | 1 byte reiskia, kad eile informacijos yra eileja ir nepriima daugau       
            jnz  .wait

        mov al, 0D4h ; komanda kontroleriui reiskia kad sekantis byte bus pelei nusiustas
        out 64h, al ; out -> nusiuncia "al" y 64h

        .wait2:
            in   al, 64h ; vel tikrina ar gali priimti informacija
            test al, 10b
            jnz  .wait2


        mov al, 0F4h           ; Leidiza pelei siusti informacija
        out 60h, al

call MainMenuAni
hlt
call MS
call ScoreDraw
call ClearScreen

MainGame:
    .waitMI: ; left click | right click | middle button | always on | pos/neg x change | pos/neg y change | x of | y of
        in   al, 64h
        test al, 01h
        jz  Idle
        test al,100000b ; 
        jz  Idle
        in   al,60h
        test al,1000b  ; if byte 3 is 1 | aligns packets     
        jz   .waitMI
        mov [mouse_b0],al
    .waitMX:; x
        in   al, 64h
        test al, 01h
        jz   .waitMX

    in   al, 60h
    mov cl,al

    .waitMY:; y
        in   al, 64h
        test al, 01h
        jz   .waitMY
    in   al, 60h

    mov word [PF],0
    cmp cl,0
    jl DecX
        test cl,cl
        jz NoChange
            mov word [PF],1
            inc word [PX]
            jmp NoChange
    DecX:
        mov word [PF],2
        dec word [PX]
    NoChange:
    inc byte [Time]
    test byte [Time],1111b
    jnz NoSpawnA
        call SpawnChick
    NoSpawnA:
    call UpdateOtherChicks
    call DrawChar
    call ScoreDraw
    sti
    hlt
    jmp MainGame

Idle:
    mov word [PF],0
    inc byte [Time]
    test byte [Time],1111b
    jnz NoSpawnB
        call SpawnChick
    NoSpawnB:

    call ScoreDraw
    call UpdateOtherChicks
    call DrawChar
    sti
    hlt
    jmp MainGame
stop:
    hlt
    jmp stop
PF dw 0
PX dw 160
boot_drive dw 0
seed dw 0
Score dw 0
nxx db 0,0,0,0
mouse_b0 db 0
Time db 0
times 510-($-$$) db 0; fill (512 bytes - ending pos of the code) with 0's. 
mark db 0x55,0xaa
MainMenuAni:
    mov cx,320*100
    FillA:
        mov word [es:di],92*256+91
        add di,2
        dec cx
        jnz FillA
        
    xor di,di
    lea si,[Tittle1]
    mov cl,8
    ScaledTextY:
        mov ch,66
        ScaledTextX:
            mov al,[si]
            test al,al
            jz SkipCell3A
                mov word [es:di],16*256+19
            SkipCell3A:
            add di,2
            inc si
            dec ch
            jnz ScaledTextX
        add di,320-66*2

        sub si,66
        mov ch,66
        ScaledTextX2:
            mov al,[si]
            test al,al
            jz SkipCell3B
                mov word [es:di],19*256+16
            SkipCell3B:
            add di,2
            inc si
            dec ch
            jnz ScaledTextX2
        add di,320-66*2
        dec cl
        jnz ScaledTextY
    lea si,[thighA]
    sub si,2

    xor ax,ax
    mov di,320+160
    add di,ax

    mov bl,1
    BootAni:
        mov di,160
        add di,ax
        mov cl,bl
        DrawBA:
            mov ch,17
            DrawBB:
                mov dx,[si]
                test dx,dx
                jnz IsCell
                    mov word [es:di],92*256+91
                    jmp skipcell
                IsCell:
                    cmp bl,100
                    jb lower
                        add dx,1
                    lower:
                    mov word [es:di],dx
                skipcell:

                sub di,2
                sub si,2
                dec ch
                jnz DrawBB
                sub di,286
            dec cl
            jnz DrawBA
        sti 
        hlt      
        add ax,320
        lea si,[thighA]
        sub si,2
        inc bl
        cmp bl,110
        jb BootAni


    ClearBoot:
    sub ax,320
    mov di,160
    add di,ax

    mov cl,111; clears shoe
    ClearBA:
        mov ch,17
        ClearBB:
            mov word [es:di],92*256+91
            sub di,2
            dec ch
            jnz ClearBB
        sub di,286
        dec cl
        jnz ClearBA

    lea si,[thighA]
    sub ax,3200

    mov di,120
    add di,ax
    mov bx,21
    CLAni:
        push si
        push di

        cmp bx,1
        jne NoSwitch
            lea si,[RealThigh]
        NoSwitch:

        mov cl,38
        DrawCLY: 
            mov ch,29
            DrawCLX:
                mov dx,[si]
                test dx,dx
                jnz IsCell2
                    mov word [es:di],92*256+91
                    jmp skipcell2
                IsCell2:
                    test dh,dh
                    jz LF
                    test dl,dl
                    jz HF
                        mov word [es:di],dx
                        jmp skipcell2
                    LF:
                        mov byte [es:di],dl
                        inc di
                        mov byte [es:di],91
                        dec di
                        jmp skipcell2
                    HF:
                        mov byte [es:di],92
                        inc di
                        mov byte [es:di],dh
                        dec di
                        jmp skipcell2
                skipcell2:
                
                add di,2
                add si,2
                dec ch
                jnz DrawCLX
            add di,262
            dec cl
            jnz DrawCLY      

        pop di
        pop si 
        add di,320
        hlt
        dec bx
        jnz CLAni
    
    mov di,6400
    lea si,[Tittle2]
    mov cl,8
    ScaledText2Y:
        mov ch,36
        ScaledTextXB:
            mov al,[si]
            test al,al
            jz SkipCell4A
                mov word [es:di],42*256+39
            SkipCell4A:
            add di,2
            inc si
            dec ch
            jnz ScaledTextXB
        add di,320-36*2

        sub si,36
        mov ch,36
        ScaledTextXB2:
            mov al,[si]
            test al,al
            jz SkipCell4B
                mov word [es:di],42*256+39
            SkipCell4B:
            add di,2
            inc si
            dec ch
            jnz ScaledTextXB2
        add di,320-36*2
        dec cl
        jnz ScaledText2Y
    mov di,26368
    lea si,[StartB]
    mov cl,30
    DrawStartBY:
        mov ch,30
        DrawStartBX:
            mov ax,[si]
            mov word [es:di],ax
            add si,2
            add di,2
            dec ch
            jnz DrawStartBX
        add di,320-60
        dec cl
        jnz DrawStartBY
    ret; noice

MS: ;Mouse check
    .waitMI: ; left click | right click | middle button | always on | pos/neg x change | pos/neg y change | x of | y of
        in   al, 64h
        test al, 01h
        jz  .waitMI
        test al,100000b ; 
        jz  .waitMI
        in   al,60h
        test al,1000b  ; if byte 3 is 1 | aligns packets     
        jz   .waitMI
        mov [mouse_b0],al
    .waitMX:; x
        in   al, 64h
        test al, 01h
        jz   .waitMX

    in   al, 60h
    mov cl,al

    .waitMY:; y
        in   al, 64h
        test al, 01h
        jz   .waitMY
    in   al, 60h

    test byte [mouse_b0],1
    jz MS
    ret
DrawChar:
    mov di,64000-320*32-16
    add di,[PX]
    mov ax,[PF]
    mov bx,1024
    mul bx
    lea si,[CharFrames]
    add si,ax
    mov ch,32
    CharFY:
        mov cl,16
        CharFX:
            mov ax,[si]
            test ax,ax
            jz SkipCCell
                mov word [es:di],ax
            SkipCCell:
            add di,2
            add si,2
            dec cl
            jnz CharFX
        add di,320-32
        dec ch
        jnz CharFY
    ret 
UpdateOtherChicks:; afk
    lea si,[ChickBuffer]
    mov ax,[CAm]
    test ax,ax
    jnz Forward
        ret
    Forward:
        mov di,[si]
        mov cl,16
        ClearPrevPosB:
            mov byte [es:di],0
            inc di
            dec cl
            jnz ClearPrevPosB
        add di,304
        mov word [si],di
        lea bp,[Chick]
        add si,2
        mov al,[si]
        test al,al
        jnz SkipDraw

        mov cl,16
        DrawA:
            mov ch,16
            DrawB:
                mov al,[bp]
                test al,al
                jz Permat
                    mov dl,[es:di]
                    cmp dl,64
                    je Eat
                Permat:

                mov byte [es:di],al
                inc bp
                inc di
                dec ch
                jnz DrawB
            add di,304
            cmp di,64960
            jb InBound
                cmp cl,14
                jne SkipOOB
                    jmp OOB
            InBound:

            dec cl
            jnz DrawA
            jmp SkipOOB
        OOB: ; kai masina paliecia limita, kordinates naujas pastato
            ; jmp Stop
            lea bp,[ChickBuffer]; KAZKODEL jeugi 2 masinos toje pacioje y asyje, tik viena pasalinta, bet kai 3 veikia??
            mov ax,[CAm]; 1 masinos
            mov cx, ax; 1 ciklai
            ; dec ax
            imul ax,3; 1x3 = 3 byte
            add bp,ax; buffer + 1 word, nuo galo ciklas
            xor ax,ax; ax = 0
            xor bx,bx
            ShuffleCarBuf:
                mov dl,[bp-1]; dl = paskutinis el
                mov dh,[bp-2]
                mov bh,[bp-3]
                dec bp
                mov byte [bp],al; paskutinis el =0
                dec bp
                mov byte [bp],ah
                dec bp
                mov byte [bp],bl
                mov ax,dx; al = dl ah = dh
                shr bx,8; ah => al

                ; mov ax,dx; paskutinis elementas bus yrasytas a;acioje esantiem elementam
                ; sub bp,2
                dec cx
                jnz ShuffleCarBuf
            dec word [CAm]
            jnz SkipOOB
            ret
        jmp SkipOOB
        SkipDraw:
        add di,320
        cmp di,64960
        ja OOB
        SkipOOB:

        
        inc si
        mov ax,[si]
        test ax,ax
        jnz Forward
    
    ret
ClearScreen:
    xor di,di
    mov cx,32000
    ClearA:
        mov word [es:di],0
        add di,2
        dec cx
        jnz ClearA
    ret 
ScoreDraw:
    inc word [Score]
    mov di,361

    mov ax,[Score]
    mov bx,10
    mov ch,5
    DrawNS:
        xor dx,dx
        div bx; liekana * 6*4
        imul dx,48
        lea bp,[Numbers]
        add bp,dx
        mov cl,8
        DrawN:
            mov dx,[bp]
            mov word [es:di],dx
            add di,2
            add bp,2
            
            mov dx,[bp]
            mov word [es:di],dx
            add di,2
            add bp,2

            mov dx,[bp]
            mov word [es:di],dx
            add di,2
            add bp,2

            add di,314
            dec cl
            jnz DrawN
        sub di,2567
        dec ch
        jnz DrawNS
    ret
SpawnChick:
    cmp word [CAm],32
    jne NotLimit
        ret
    NotLimit:

    mov ax,[seed]
    imul ax,109
    add ax,1021
    mov word [seed],ax
    mov bp,ax

    shr ax,8
    xor dx,dx
    mov bx,320
    div bx
    add dx,4816
    mov di,dx
    mov al,[es:di]
    test al,10000b
    jz ContinueN
        ret
    ContinueN:
    sub dx,4480

    lea si,[ChickBuffer]
    
    mov ax,[CAm]
    imul ax,3
    add si,ax

    mov word [si],dx
    add si,2
    mov byte [si],0
    inc word [CAm]
    ret
Eat:
    mov bl,[si]
    test bl,bl
    jnz Permat
    add word [Score],100
    mov byte [si],1
    mov dx,di
    mov bx,cx
    DrawCXA:
        dec di
        mov byte [es:di],0
        
        inc ch
        test ch,10000b ; jeigu ne 16, kartoja
        jz DrawCXA
    sub di,304

    DrawCYA:
        mov ch,8
        DrawCXB:
            sub di,2
            mov word [es:di],17*256
            dec ch
            jnz DrawCXB
        sub di,304
        inc cl
        test cl,10000b
        jz DrawCYA
    mov di,dx
    mov cx,bx
    jmp Permat
ChickBuffer:
dw 156; index
db 1; car type
db 63*3 dup(0)
CAm dw 1
incbin "Game of THighns/Tigh?.raw"
thighA:
incbin "Game of THighns/ChikenLeg.raw"
RealThigh:
incbin "Game of THighns/ThighReal.raw"
Tittle1:
incbin "Game of THighns/GameAbout_.raw"
Tittle2:
incbin "Game of THighns/ThighTxt2.raw"
StartB:
incbin "Game of THighns/StartB60x30.raw"
CharFrames:
incbin "Game of THighns/32x32CA.raw"
incbin "Game of THighns/32x32CB.raw"
incbin "Game of THighns/32x32CC.raw"

Chick:
incbin "Game of THighns/16x16Chick.raw"
Numbers:
incbin "Game of THighns/N6x8/0.raw"
incbin "Game of THighns/N6x8/1.raw"
incbin "Game of THighns/N6x8/2.raw"
incbin "Game of THighns/N6x8/3.raw"
incbin "Game of THighns/N6x8/4.raw"
incbin "Game of THighns/N6x8/5.raw"
incbin "Game of THighns/N6x8/6.raw"
incbin "Game of THighns/N6x8/7.raw"
incbin "Game of THighns/N6x8/8.raw"
incbin "Game of THighns/N6x8/9.raw"