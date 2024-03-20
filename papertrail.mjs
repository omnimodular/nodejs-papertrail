/**
 * @omnimodular/papertrail
 *
 *
 * Changes
 * -------
 *
 * 2022-12-30   Initial version. @cdahlin
 * 2023-01-22   Added try-catch block. @hholst
 * 2023-11-12   Change authentication method to HTTP Bearer.  @hholst
 * 2023-11-15   Use an https agent with keep-alive. @hholst
 * 2023-11-30   Include optional program argument. @hholst
 *
 *
 * Severity levels
 * ---------------
 *
 *  Numerical         Severity
 *    Code
 *
 *     0       Emergency: system is unusable
 *     1       Alert: action must be taken immediately
 *     2       Critical: critical conditions
 *     3       Error: error conditions
 *     4       Warning: warning conditions
 *     5       Notice: normal but significant condition
 *     6       Informational: informational messages
 *     7       Debug: debug-level messages
 **/

import fetch from "node-fetch"
import https from "node:https"
import os from "node:os"

const papertrailToken = process.env.PAPERTRAIL_TOKEN
const papertrailUrl = process.env.PAPERTRAIL_URL
const httpsAgent = new https.Agent({ keepAlive: true })
const hostname = os.hostname()
const program = "app"
const prival = 14    // 1 * 8 + 6 = informational; see Table 'Severity levels'.

export default async function log(message, opts = { hostname, program, prival }) {
    const { hostname, program, prival } = opts
    const msg = (typeof message === "string") ? message : JSON.stringify(message)
    const syslogMessage = `<${prival}>1 ${new Date().toISOString()} ${hostname} ${program} - - - ${msg}`

    if (!papertrailToken || !papertrailUrl) {
        console.log(syslogMessage)
        return
    }

    try {
        await fetch(
            papertrailUrl,
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/octet-stream',
                    'Authorization': `Bearer ${papertrailToken}`,
                },
                body: Buffer.from(syslogMessage),
                agent: httpsAgent,
            }
        )
    }
    catch (err) {
        console.error(`Papertrail error: ${err.message}`)
        console.error(err.stack)
    }
}
