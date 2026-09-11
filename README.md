# Proyecto_Ensamblador

El proposito de este codigo es que a partir de un arreglo de 10 elementos, imprimir en consola la dirección del elemento y su valor en  hexadecimal.

Instrucciones de compilación

1. Abrimos un CMD en la direccion donde tenemos el .asm y escribimos:
```
uasm64 -win64 [nombre_del_archivo].asm
```
2. Luego con un linker, en mi caso golink, escribimos el siguiente comando:
```
golink [nombre_del_archivo].obj kernel32.dll /fo [nombre_del_archivo].exe /console /entry main
```

3. Para abrir en programa desde la consola escribimos:
```
.\[nombre_del_archivo].exe
```

Salida esperada con los elementos del arreglo [10, 20, 30,... 100]

