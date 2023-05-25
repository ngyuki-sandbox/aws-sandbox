import * as mysql from 'mysql2/promise'

export async function handler(context) {
    const config = {
        host: context['MYSQL_HOST'],
        user: context['MYSQL_USER'],
        password: context['MYSQL_PASSWORD'],
        database: context['MYSQL_DATABASE'],
    };
    const sql = context['MYSQL_SQL'];
    console.log({config, sql});
    const connection = await mysql.createConnection(config);
    const stmt = await connection.prepare(sql);
    const [result] = await stmt.execute();
    console.log({result});
}
