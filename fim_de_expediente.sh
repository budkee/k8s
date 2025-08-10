#!/bin/zsh
# 
# Repositório no GitHub: https://github.com/budkee/k8s
#
# Alterar a mensagem conforme o que foi feito no dia 
echo "\n# ============== Adding files ============== #"
git add .
echo "\n# ============== Commiting ============== #"

git commit -m "K8s - Lab 1 | 10/08/25"

echo "\n# ============== Pushing ============== #"
git push
echo "\n# ============== Status ============== #"
git status
