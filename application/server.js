'use strict';

const express = require('express')
const cors = require('cors');
const app = express()
const bodyParser = require('body-parser')
const port = 3000

const path = require('path');
const initHyperlegerFabric = require(path.resolve( __dirname, 'hyperleger-fabric', 'init'));

require('dotenv').config();

const prettyJSONString = (inputString) => (JSON.stringify(JSON.parse(inputString), null, 2));

// bodyParser
app.use(bodyParser.json());

app.use(cors());

((async () => {
  const contract = await initHyperlegerFabric();

  // Register endpoints
  app.get('/', async (req, res) => {
    let result = await contract.evaluateTransaction('GetAllAssets')
    res.send(prettyJSONString(result));
  });

  app.get('/:asset', async (req, res) => {
      let asset = req.params.asset;
      let result = await contract.evaluateTransaction('ReadAsset', asset);
      res.send(prettyJSONString(result));
  });

  app.post('/createAsset', async (req, res) => {
    let asset = {
      id: req.body.id,
      advertisementId: req.body.advertisementId,
      publisherId: req.body.publisherId,
      advertiserId: req.body.advertiserId,
      timeStamp: req.body.timeStamp,
    };

    let result = await contract.submitTransaction('CreateAsset', asset.id, asset.advertisementId, asset.publisherId, asset.advertiserId, asset.timeStamp);
    res.send(prettyJSONString(result));
});

  app.listen(port, () => {
    console.log(`Example app listening at http://localhost:${port}`)
  })

})());