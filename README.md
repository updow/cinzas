# Cinzas — protótipo 3D pós-apocalíptico (Godot 4.3)

Mundo aberto de teste. Tudo é gerado por código (sem assets binários), então edita bem no Godot mobile e versiona bem no git.

## Mecânicas incluídas
| Sistema | Onde | Como testar |
|---|---|---|
| Fome, sede, estamina, vida | `player.gd` | Barras no topo esquerdo. Correr gasta mais. Zerou fome/sede = perde vida |
| Coleta de itens | `pickup.gd`, `main.gd` | Ande até latas, garrafas, sucata, madeira, galões, munição |
| Comer/Beber | `player.gd` | Botões Comer / Beber |
| Combate | `player.gd`, `enemy.gd` | Golpe (curta distância) e Atirar (gasta munição) |
| Inimigos | `enemy.gd` | Vagueiam, perseguem a 22 m, atacam de perto, dropam loot |
| Veículo | `vehicle.gd` | Chegue perto do carro laranja → Ação. Freio = botão Pular. Atropela inimigos |
| Base | `base_builder.gd` | Botão Base → Peça (Piso/Parede/Fogueira) → Pôr. Fogueira cura por perto |

Controles de toque: joystick à esquerda, arrastar à direita para olhar.
Teclado (PC): WASD, Shift correr, Espaço pular/freio, E ação, F golpe, R atirar, 1 comer, 2 beber, B base, Tab peça, Enter pôr, botão direito do mouse para olhar.

## Estrutura
- `scripts/main.gd` — monta mundo: céu, terreno, ruínas, árvores, loot, spawn de inimigos
- `scripts/terrain.gd` — terreno low-poly + colisão (`height_at(x,z)`)
- `scripts/character_model.gd` — boneco procedural (jogador e inimigos)
- `scripts/controls.gd` — autoload `Ctrl` (teclado + toque)
- `scripts/ui.gd` — HUD e botões virtuais

## Rodar no Godot
Abra a pasta como projeto (Godot 4.3+, renderer GL Compatibility) e dê Play.

## Build pelo git
Faça push para a branch `main`: o workflow `.github/workflows/android.yml` gera o APK debug em *Actions → Artifacts*.

## Ajustes conhecidos
- Carro andando de ré ao acelerar → `ENGINE_SIGN = -1.0` em `vehicle.gd`. Muito lento/rápido → `ENGINE_POWER`.
- O primeiro carregamento gera o terreno (alguns segundos no celular).
- Peças de base usam a altura do terreno no centro; em ladeiras podem ficar com vãos.

## Próximos passos sugeridos
Salvar/carregar base e inventário, baú de armazenamento, ciclo dia/noite, mais tipos de inimigo, 2º veículo, crafting.
