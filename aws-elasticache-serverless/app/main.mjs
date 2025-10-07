import * as fs from "fs/promises";
import Redis from "ioredis";
import { hrtime } from "process";

function initRedis() {
    const ELASTICACHE_HOST = process.env.ELASTICACHE_HOST;
    const ELASTICACHE_TLS = process.env.ELASTICACHE_TLS;

    const cluster = new Redis.Cluster(
        [{ host: ELASTICACHE_HOST, port: 6379 }],
        {
            dnsLookup: (address, callback) => callback(null, address),
            scaleReads: 'slave',
            slotsRefreshInterval: 10000,
            slotsRefreshTimeout: 20000,
            redisOptions: {
                ...(ELASTICACHE_TLS ? { tls: {} } : {}),
                connectTimeout: 5000,
                keepAlive: 10000,
                autoResendUnfulfilledCommands: false,
                lazyConnect: true,
            },
            lazyConnect: true,
            enableReadyCheck: true,
            clusterRetryStrategy: function(times) {
                return Math.min(1000 * times, 30000);
            },
        }
    );

    cluster.on('connect', () => {
        console.log('[redis] connect');
    });
    cluster.on('ready', () => {
        console.log('[redis] ready');
    });
    cluster.on('close', () => {
        console.log('[redis] close');
    });
    cluster.on('reconnecting', () => {
        console.log('[redis] reconnecting');
    });
    cluster.on('error', async (err) => {
        console.error('[redis] error:', String(err));
    });
    cluster.on('node error', (node, err) => {
        console.warn(`[redis] node error node: ${JSON.stringify(node)}, err: ${String(err)}`);
    });

    return cluster;
}

(async () => {
    const dummy = await fs.readFile("./dummy.txt", 'utf-8');
    const time = process.env.TIME ? Number(process.env.TIME) : 60;
    const date = process.env.DATE;

    console.log(`time=${time} date=${date}`);

    async function demo() {
        const cluster = initRedis();
        try {
            let exit = false;
            let reqs = 0;
            let errs = 0;
            let duration = BigInt(0);
            let statd = false;

            await Promise.race([
                new Promise(resolve => {
                    setTimeout(resolve, 3000);
                }),
                new Promise(resolve => {
                    cluster.once('ready', resolve);
                    cluster.once('reconnecting', resolve);
                    cluster.connect();
                }),
            ]);

            function stat() {
                if (statd) {
                    return;
                }
                statd = true;
                const oks = reqs - errs;
                console.log(JSON.stringify({
                    date: date,
                    reqs: reqs,
                    errs: errs,
                    rps: (reqs / time).toFixed(2),
                    duration: oks ? (Number(duration / BigInt(reqs - errs)) / 1e6).toFixed(2) : undefined,
                }));
            }

            setTimeout((() => {
                exit = true;
                setTimeout((() => {
                    stat();
                    process.exit(1);
                }), 1000 * 15);
            }), time * 1000);

            while (!exit) {
                try {
                    const start = hrtime.bigint();
                    const key = Math.floor(Math.random() * 1000);
                    if (Math.random() < 0.1) {
                        await Promise.race([
                            timeout(1000),
                            Promise.all([
                                cluster.setex(key, 6000000, dummy),
                            ]),
                        ]);
                    } else {
                        await Promise.race([
                            timeout(1000),
                            Promise.all([
                                cluster.get(key),
                                cluster.pttl(key),
                            ]),
                        ]);
                        duration += (hrtime.bigint() - start);
                    }
                } catch (err) {
                    errs++;
                }
                reqs++;
            }
            stat();
        } catch (err) {
            console.error(err);
        } finally {
            await cluster.quit();
            cluster.disconnect();
            process.exit(1);
        }
    }

    await demo();
})();

function timeout(ms) {
    return new Promise((_, reject) => {
        setTimeout(() => {
            const error = new Error("Executed timeout " + ms + " ms");
            reject(error);
        }, ms);
    });
}
