import React, { useState, useEffect } from 'react';

function App() {
  const [data, setData] = useState(null);
  const [health, setHealth] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Fetch health status
    fetch('/health')
      .then(res => res.json())
      .then(data => setHealth(data))
      .catch(err => setError('Health check failed'));

    // Fetch api1 data
    fetch('/api1')
      .then(res => res.json())
      .then(data => setData(data))
      .catch(err => setError('Failed to fetch API data'));
  }, []);

  return (
    <div style={styles.container}>
      <h1 style={styles.title}>DevOps Assessment Dashboard</h1>

      {/* Health Status */}
      <div style={styles.card}>
        <h2 style={styles.cardTitle}>System Health</h2>
        {health ? (
          <div style={styles.healthBadge}>
            ● Status: {health.status.toUpperCase()}
            <br />
            <small>Last checked: {health.timestamp}</small>
          </div>
        ) : (
          <p>Checking health...</p>
        )}
      </div>

      {/* API1 Data */}
      <div style={styles.card}>
        <h2 style={styles.cardTitle}>API Data</h2>
        {error && <p style={styles.error}>{error}</p>}
        {data ? (
          <div>
            <p style={styles.message}>{data.message}</p>
            <table style={styles.table}>
              <thead>
                <tr>
                  <th style={styles.th}>ID</th>
                  <th style={styles.th}>Name</th>
                </tr>
              </thead>
              <tbody>
                {data.data.map(item => (
                  <tr key={item.id}>
                    <td style={styles.td}>{item.id}</td>
                    <td style={styles.td}>{item.name}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <small style={styles.timestamp}>Fetched at: {data.timestamp}</small>
          </div>
        ) : (
          <p>Loading data...</p>
        )}
      </div>
    </div>
  );
}

const styles = {
  container: {
    maxWidth: '800px',
    margin: '40px auto',
    fontFamily: 'Arial, sans-serif',
    padding: '0 20px',
    backgroundColor: '#0d1117',
    minHeight: '100vh',
    color: '#c9d1d9'
  },
  title: {
    textAlign: 'center',
    color: '#58a6ff',
    borderBottom: '1px solid #30363d',
    paddingBottom: '20px'
  },
  card: {
    backgroundColor: '#161b22',
    border: '1px solid #30363d',
    borderRadius: '8px',
    padding: '20px',
    marginBottom: '20px'
  },
  cardTitle: {
    color: '#58a6ff',
    marginTop: 0
  },
  healthBadge: {
    color: '#3fb950',
    fontSize: '16px',
    lineHeight: '1.8'
  },
  message: {
    color: '#8b949e',
    marginBottom: '15px'
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse'
  },
  th: {
    backgroundColor: '#21262d',
    padding: '10px',
    textAlign: 'left',
    border: '1px solid #30363d',
    color: '#58a6ff'
  },
  td: {
    padding: '10px',
    border: '1px solid #30363d'
  },
  timestamp: {
    color: '#8b949e'
  },
  error: {
    color: '#f85149'
  }
};

export default App;
