const postgres = require('postgres');

// Conexión a Shard LAS (Latinoamérica Sur)
const sqlLAS = postgres(
  'postgres://postgres:shardpass@localhost:5432/lol_shard_las',
  {
    host: 'localhost',
    port: 5432,
    database: 'lol_shard_las',
    username: 'postgres',
    password: 'shardpass',
  }
);

// Conexión a Shard LAN (Latinoamérica Norte)
const sqlLAN = postgres(
  'postgres://postgres:shardpass@localhost:5433/lol_shard_lan',
  {
    host: 'localhost',
    port: 5433,
    database: 'lol_shard_lan',
    username: 'postgres',
    password: 'shardpass',
  }
);

async function insertUser(data) {
  const { id, nombre_summoner, region, nivel, estado_cuenta } = data;
  let sql;

  if (region === 'LAS') {
    sql = sqlLAS;
  } else if (region === 'LAN') {
    sql = sqlLAN;
  } else {
    // Hash simple: par -> LAS, impar -> LAN
    sql = (id % 2 === 0 ? sqlLAS : sqlLAN);
  }

  await sql`
    INSERT INTO Usuarios (usuario_id, nombre_summoner, region, nivel, estado_cuenta)
    VALUES (${id}, ${nombre_summoner}, ${region}, ${nivel}, ${estado_cuenta})
  `;
  console.log(`Inserted user ${id} into ${sql === sqlLAS ? 'shard_las' : 'shard_lan'}`);
}

async function getUsersFrom(region) {
  let sql;
  if (region === 'LAS') sql = sqlLAS;
  else if (region === 'LAN') sql = sqlLAN;
  else throw new Error('Region debe ser LAS o LAN');

  const users = await sql`SELECT * FROM Usuarios WHERE usuario_id > 30000;`;
  console.log(`Users in shard ${region}:`, users);
  return users;
}

async function getAllUsers() {
  const [lasUsers, lanUsers] = await Promise.all([getUsersFrom('LAS'), getUsersFrom('LAN')]);
  return [...lasUsers, ...lanUsers];
}

async function main() {
  await insertUser({ id: 30004, nombre_summoner: 'Alice', region: 'LAS', nivel: 10, estado_cuenta: 'activo' });
  await insertUser({ id: 30005, nombre_summoner: 'Bob', region: 'LAN', nivel: 15, estado_cuenta: 'activo' });
  await insertUser({ id: 30006, nombre_summoner: 'Carol', region: 'NA', nivel: 8, estado_cuenta: 'suspendido' });

  await getAllUsers();
}

main().catch(err => console.error(err));
