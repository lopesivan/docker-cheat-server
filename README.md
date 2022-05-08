# Questão: como buildar?

O primeiro build:
```bash
eval "$(pyenv vars)"
make build up log
```

em uma máquina externa sem *pyenv*:
```bash
export GITHUB_USER=lopesivan
make config build up log
```

# Questão: substitui localhost por redis

O aplicativo não se conectava com o banco de dados, pois este
buscava por localhost:6379 então substituimos pelo valor
nomeado em depends_on.

trecho importante do arquivo docker-compose.yaml
```txt
    depends_on:
      - redis
```

arquivos alterados:
```bash
cd root/app/cheat.sh
vi lib/config.py  bin/clean_cache.py
    localhost -> redis
```


# Usando
```
 git clone https://github.com/lopesivan/docker-cheat-server cheat
 cd cheat/
 git clone https://github.com/lopesivan/upstream
 make up
```

