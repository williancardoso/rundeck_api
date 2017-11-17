# rundeck_api

### Gerar o cookie
```
RUNDECK_HOST=http://10.30.182.171/rundeck
./login.sh $RUNDECK_HOST
```

Lista projetos
```
curl -s -b ./cookies $RUNDECK_HOST/api/1/projects
```
