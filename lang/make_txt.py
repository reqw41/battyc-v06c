#!/usr/bin/env python3
"""Генерирует lang/ru/txt_*.asm из русских строк. Запуск из корня дерева: python3 lang/make_txt.py
Английские строки (lang/en/txt_*.asm) — исходные из оригинала, они не генерируются.
Кодировка знакогенератора (lang/ru/font.asm): 0-9, А-Я без Ё ($0A-$29), '.', ',', ' ', '-', '=', Y.
Формат сообщения: X, Y, цвет, длина, текст."""
import os

ALPHABET = "0123456789АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ., -=Y"
# BATTY и подобное набирается похожими русскими буквами
LATIN = str.maketrans("ABEKMHOPCTX", "АВЕКМНОРСТХ")


# Заголовки меню: восемь ячеек знаков $30-$39, «ИГРОК n» со сдвигом на 4 точки (см. lang/ru/font.asm)
HEADINGS = {"\u2460": [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37],
            "\u2461": [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x38, 0x39]}


def enc(text):
    if text in HEADINGS:
        return HEADINGS[text]
    return [ALPHABET.index(ch) for ch in text.translate(LATIN)]


def msg(x, y, color, text):
    codes = enc(text)
    out = ["  DEFB $%02X,$%02X,%s,$%02X" % (x, y, color, len(codes))]
    for i in range(0, len(codes), 8):
        line = "  DEFB " + ",".join("$%02X" % c for c in codes[i:i + 8])
        out.append(line + ("\t; " + text if i == 0 else ""))
    return "\n".join(out) + "\n"


def table():
    rows = []
    ys = [0x27, 0x38, 0x49, 0x5A, 0x6B, 0x7C, 0x8D, 0x9E, 0xAF, 0xC0]
    bright = ["c47", "c47", "c46", "c46", "c45", "c45", "c44", "c44", "c43", "c43"]
    for i, y in enumerate(ys):
        rows.append(msg(0x30 if i == 9 else 0x38, y, bright[i], "%d." % (i + 1)))
    colors = ["c47", "c07", "c46", "c06", "c45", "c05", "c44", "c04", "c43", "c03"]
    for i, y in enumerate(ys):
        name = "Х И Т" if i % 2 == 0 else "П А К"
        rows.append(msg(0x58, y, colors[i], "%06d   %s" % ((10 - i) * 10000, name)))
    return rows


FILES = {
    "txt_main_menu": [msg(0x08, 0x01, "c07", "\u2460"), msg(0xB8, 0x01, "c07", "\u2461")],
    "txt_score_1up": [msg(0x10, 0x09, "c07", "000000")],
    "txt_score_2up": [msg(0xC0, 0x09, "c07", "000000")],
    "txt_1_player": [msg(0x50, 0x29, "c44", "1 - 1 ИГРОК")],
    "txt_2_players": [msg(0x50, 0x3D, "c44", "2 - 2 ИГРОКА")],
    "txt_double_play": [msg(0x50, 0x51, "c44", "3 - ВДВОЕМ"),
                        msg(0x50, 0xB1, "c44", "0 - НАЧАТЬ ИГРУ")],
    "txt_controls": [msg(0x60, 0x7D, "c45", "КЛАВИШИ"),
                     msg(0x60, 0x95, "c45", "ДЖОЙСТИК"),
                     msg(0x50, 0xC9, "c47", "ХИТ ПАК 1987"),
                     msg(0x70, 0x01, "c47", "BATTY"),
                     msg(0x70, 0x08, "c46", "=====")],
    # цифра игрока вписывается кодом в последний знак (txt_player_x+11)
    "txt_player_x": [msg(0x58, 0x8F, "c47", " ИГРОК 0")],
    # номер раунда вписывается в два последних знака (txt_round_xx+10,+11)
    "txt_round_xx": [msg(0x60, 0x9E, "c47", "РАУНД 00")],
    "txt_game_on": [msg(0x68, 0x8F, "c47", "ИГРАЕМ")],
    "txt_game_over": [msg(0x58, 0x8F, "c47", "КОНЕЦ ИГРЫ")],
    # цифра игрока вписывается в последний знак (txt_player_0+$0C)
    "txt_player_0": [msg(0x50, 0x9E, "c47", "  ИГРОК 0")],
    "txt_players_1_and_2": [msg(0x50, 0x9E, "c47", "ИГРОКИ 1 И 2")],
    # цифра игрока вписывается в десятый знак (txt_player_0_enter_your_name+13)
    "txt_player_0_enter_your_name": [msg(0x50, 0x01, "c47", "   ИГРОК 0  "),
                                     msg(0x40, 0x09, "c47", "ВВЕДИТЕ ВАШЕ ИМЯ")],
    "txt_high_score_table": table(),
    "txt_high_scores": [msg(0x68, 0x01, "c47", "РЕКОРДЫ"), msg(0x68, 0x08, "c46", "=======")],
}

here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ru")
for name, parts in FILES.items():
    with open(os.path.join(here, name + ".asm"), "w", encoding="utf-8") as f:
        f.write(name + ":\n\n" + "\n".join(parts))
