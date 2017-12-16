var express = require('express');
var app = express();

app.use(express.static('.'));

require('isomorphic-fetch');

app.get('/languages/:login', function(req, res) {
  getLanguages(req.params.login)
    .then(d => res.send(d))
    .catch(e => console.log('error', e));
});
app.listen(3000, () => console.log('Listening on port 3000'));

function getLanguages(login) {
  const variables = { login };
  const token = process.env.GITHUB_TOKEN;
  const query = `query ($login:String!){
  repositoryOwner(login:$login) {
    repositories(first: 100, privacy: PUBLIC, isFork:false, orderBy: {field: UPDATED_AT, direction:DESC }) {
      edges {
        node {
          name
          languages(first: 10) {
            edges {
              size
              node {
                name
              }
            }
          }
        }
      }
    }
  }
}`;
  console.log('getting', query, variables);
  return fetch('https://api.github.com/graphql', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: 'Bearer ' + token
    },
    body: JSON.stringify({ query, variables })
  })
    .then(response => response.json())
    .then(({ data }) =>
      data.repositoryOwner.repositories.edges.reduce(
        (acc, val) =>
          val.node.languages.edges
            .map(({ node: { name }, size }) => ({ name, size }))
            .reduce((acc, d) => {
              acc[d.name] = (acc[d.name] || 0) + d.size;
              return acc;
            }, acc),
        {}
      )
    )
    .then(data =>
      Object.entries(data)
        .map(([language, count]) => ({ language, count }))
        .sort((a, b) => b.count - a.count)
        .filter((_, i)=> i < 10)
    )
    .catch(error => console.log(error));
}
