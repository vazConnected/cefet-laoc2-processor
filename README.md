# Prática 2 - LAOC2
Projeto 2 da disciplina Laboratório de Arquitetura e Organização de Computadores 2 do Cefet-MG.

## Objetivo
Esta prática tem finalidade de exercitar os conceitos relacionados à implementação de um processador.

## Projeto
O [processador](/projeto/) deve implementar as seguintes instruções:
- **LD**: Rx <- [[Ry]]
- **ST**: [Ry] <- [Rx]
- **MVNZ**: if (G != 0) [Rx] <- [Ry]
- **MV**: Rx <- [Ry]
- **MVI**: Rx <- D
- **ADD**: Rx <- [Rx] + [Ry]
- **SUB**: Rx <- [Rx] - [Ry]
- **OR**: Rx <- [Rx] || [Ry]
- **SLT**: if (Rx < Ry) [Rx] = 1; else [Rx] = 0;
- **SLL**: Rx = [Rx] << [Ry]
- **SRL**: Rx = [Rx] >> [Ry]

A partir da implementação, o processador desenvolvido deve ser capaz de executar programas que utilizem esse conjunto de instruções e exibir o estado dos registradores no display de 7 segmentos.

## Créditos
- Autores: Pedro Vaz e Roberto Gontijo;
- Mentora: Daniela Cascini.
