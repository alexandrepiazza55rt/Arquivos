from time import sleep
from random import choice

print('=' * 30)
print(f'\033[34m{f"Roleta Russa":^30}\033[m')
print('=' * 30)

valores = ['Falhou', 'Falhou', 'Falhou', 'Falhou', 'Falhou', 'Morreu']

cont = 0
for c in range(1, 7):
    print('Girando!')
    for i in range(30):
        sleep(0.1)
        print(f'{chr(46)}', end='')
    print()
    x = choice(valores)
    cont += 1
    if x != valores[-1]:
        print(f'\033[32m{cont}º disparo {x}!\033[m')
        if cont == 6:
            print(f'\033[34mVocê é muito Sortudo! Continua Vivo!\033[m')
    else:
        print(f'\033[31m{x}! No {cont}º disparo!\033[m')
        break