'use strict';

const request = (body, options, protocal_method, customCatch) => {
    return new Promise((resolve, reject) => {
        const protocal = require(protocal_method);
        const req   = protocal.request(options, response => {
            if (customCatch && customCatch.code && response.statusCode === customCatch.code) {
                console.log(customCatch.message);
            }
            else if (response.statusCode < 200 || response.statusCode > 299) {
                reject(new Error('Failed to load json, status code: ' + response.statusCode + ' ' + response.statusMessage));
            }
            const body = [];
            response.on('data', chunk => body.push(chunk));
            response.on('end', () => resolve(JSON.parse(body.join(""))));
        });
        req.on('error', (err) => reject(err));
        req.write(body);
        req.end();
    });
};

const options = {
    headers: {
        "Content-Type": 'application/json',
        authorization: 'Basic ' + new Buffer('verify-domain-lambda:' + process.env.CP_API_KEY  ).toString('base64')
    },
    hostname: "dev.centralpark.2u.com",
    ssl: true,
    port: '443',
    path: '/graphql',
    method: 'POST'
};

exports.forward_delegation_alert = (event, context, callback) => {
    const dns = event.check_params.hostname.replace('pingdom.', '');
    const date_of_delegation = new Date().toISOString().slice(0, 19) + 'Z';

    const queryBody = () => {
        const query = `query date { dnsDomains(name: \"${dns}\") { delegationDate }}`;
        return {
            query: query,
            variables: null
        };
    };

    const mutationBody = () => {
        const mutation = {dnsDomain:[{name:  dns, delegationDate: date_of_delegation }]};
        return {
            query: "mutation UpdateDateOfDelegation($entities: JSON!) { update(entities: $entities) }",
            variables: { entities: JSON.stringify(mutation) }
        };
    };

    return request(JSON.stringify(queryBody()), options, 'https')
        .then(resp =>  {
            const isDelegated = resp.data.dnsDomains[0].delegationDate;
            if (isDelegated) {
                console.log('[INFO] Already Delegated. Exiting...');
                callback(null, resp);
            } else {
                console.log('[INFO] Sending Delegation Date to Central Park...');
                request(JSON.stringify(mutationBody()), options, 'https').then(resp => callback(null, resp));
            }
        });
};


