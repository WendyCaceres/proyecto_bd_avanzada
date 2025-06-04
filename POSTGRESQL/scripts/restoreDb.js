const { exec } = require('child_process');
const path   = require('path');
const fs     = require('fs');

const CONTAINER          = 'leagueoflegends2'; 
const DB_USER            = 'postgres';
const DB_NAME            = 'lol_economia';   
const BACKUP_FILE_HOST   = path.join(__dirname, '../', 'backups', 'backup_lol_economia_2025-06-04.dump');

console.log('\n▶ Iniciando restauración de PostgreSQL');

if (!fs.existsSync(BACKUP_FILE_HOST)) {
  console.error(`🔴 ERROR: No se encontró el archivo de backup en el host:\n   ${BACKUP_FILE_HOST}`);
  process.exit(1);
}

const BASENAME            = path.basename(BACKUP_FILE_HOST);
const CONTAINER_TMP_PATH  = `/tmp/${BASENAME}`;

console.log(`  • Contenedor:       ${CONTAINER}`);
console.log(`  • Usuario Postgres: ${DB_USER}`);
console.log(`  • Base a restaurar: ${DB_NAME}`);
console.log(`  • Archivo backup:   ${BACKUP_FILE_HOST}`);
console.log(`  • Dentro del contenedor se copiará a: ${CONTAINER_TMP_PATH}\n`);

const copyCmd = `docker cp "${BACKUP_FILE_HOST}" ${CONTAINER}:${CONTAINER_TMP_PATH}`;

const restoreCmd = `docker exec -u ${DB_USER} ${CONTAINER} ` +
                   `pg_restore -U ${DB_USER} -d ${DB_NAME} --clean "${CONTAINER_TMP_PATH}"`;

const cleanupCmd = `docker exec ${CONTAINER} rm -f ${CONTAINER_TMP_PATH}`;

console.log(`▶︎ Copiando backup al contenedor...`);
exec(copyCmd, (errCopy, _stdoutCopy, stderrCopy) => {
  if (errCopy) {
    console.error(`🔴 Error al copiar archivo al contenedor:\n${stderrCopy || errCopy.message}`);
    process.exit(2);
  }
  console.log(`✅ Archivo copiado a ${CONTAINER}:${CONTAINER_TMP_PATH}\n`);

  console.log(`▶︎ Ejecutando restauración con pg_restore...`);
  console.log(`  Comando: ${restoreCmd}\n`);
  exec(restoreCmd, (errRestore, _stdoutRestore, stderrRestore) => {
    if (errRestore) {
      console.error(`🔴 Error durante pg_restore:\n${stderrRestore || errRestore.message}`);
      process.exit(3);
    }
    console.log(`✅ Restauración completada correctamente en la base "${DB_NAME}".\n`);

    console.log(`▶︎ Eliminando archivo temporal dentro del contenedor...`);
    exec(cleanupCmd, (errClean, _stdoutClean, stderrClean) => {
      if (errClean) {
        console.warn(`⚠️ No se pudo borrar el archivo temporal en contenedor:\n${stderrClean || errClean.message}`);
      } else {
        console.log(`✅ Archivo ${CONTAINER_TMP_PATH} eliminado en el contenedor.\n`);
      }
      console.log(`🎉 ¡Base de datos PostgreSQL "${DB_NAME}" restaurada exitosamente!`);
      process.exit(0);
    });
  });
});
