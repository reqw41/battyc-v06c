GameOverPlayerLine:
 ld a,(game_mode)
 cp 2
 jp z,print_txt_players_1_and_2
 jp print_line
