import React from 'react';
import './App.css';

class App extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            'wsStatus': false,
            'wsPort': 0,
            'wsClients': [],
            'httpSatus': false,
            'httpPort': 0,
            'log': []
        };
    }

    componentDidMount() {
        this.testAPI();
        this.statusInterval = setInterval(() => this.testAPI(), 2000);
    }

    componentWillUnmount() {
        clearInterval(this.statusInterval);
    }

    testAPI() {
        fetch('http://localhost:8080/server-status')
            .then(res => res.text())
            .then(text => JSON.parse(text))
            .then(json => {
                this.setState({
                    'wsStatus': json.ws.status,
                    'wsPort': json.ws.port,
                    'wsClients': json.ws.clients,
                    'httpStatus': json.http.status,
                    'httpPort': json.http.port,
                    'log': json.log
                });
            })
            .catch(err => err);
    }

    render() {
        var logLines = this.state.log.map(line => {
            return(
                <tr><td>{ line }</td></tr>
            );
        });
        return (
            <div className="App">
              <header className="App-header">
                <h3>Art of Tinkering Relay Server</h3>
                  <table>
                    <tr>
                        <td>HTTP Server status:</td>
                        <td className={this.state.httpStatus ? 'running' : 'stopped'}>
                          {this.state.httpStatus ? 'started' : 'stopped'}
                        </td>
                    </tr>
                    <tr>
                      <td>WebSocket Server status:</td>
                      <td className={this.state.wsStatus ? 'running' : 'stopped'}>
                        {this.state.wsStatus ? 'started' : 'stopped'}
                      </td>
                    </tr>
                    <tr>
                      <td>WebSocket Client(s) connected:</td>
                      <td>{this.state.wsClients.length}</td>
                    </tr>
                </table>
                <div className='console-container'>
                  <table className='log-console'>
                      { logLines }
                  </table>
                </div>
              </header>
            </div>
        );
    }
}

export default App;
