Archivos necesarios para inicar un servidor mqtt seguro con mqtt 
Para esto necesitamos tener instalador docker y docker-compose 

Ejecutar el siguiente comando en tu servidor linux 
sudo chmod +x ./init-letsencrypt.sh
Esto es para dar permisos de ejecucion al script que creara los virtualhost y certificados
Se pedira algunos datos para poder registrar el dominio "No deben ser vacios"
1- Nombre del Dominio 
2 - Se Consulta si desea hacer pruebas con el certificado
  *Presionar Enter para Continuar sin hacer prueba de certificado.
  *Presionar y si desea hacer pruebas de certificado.
  Por ultimo se pedira un email Para informar sobre el estado del Dominio.
  al terminar ejecutar el comando:
   - docker-compose -f production_nginx.yml up -d
Este comando inica el servicio certbot el cual se encargar de actualizar periodicamente el Certificado
 Link video Explicativo:

-  https://www.youtube.com/watch?v=hKJZyLIOy_k
