import { useState } from 'react';
import Head from 'next/head';

export default function Home() {
  const [input, setInput] = useState('');
  const [output, setOutput] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [pingResponse, setPingResponse] = useState('');
  const [pingLoading, setPingLoading] = useState(false);
  const [showHowItWorks, setShowHowItWorks] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setOutput('');

    try {
      const response = await fetch('/api/proxy', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message: input }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();
      setOutput(JSON.stringify(result, null, 2));
    } catch (err) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handlePing = async () => {
    setPingLoading(true);
    setError('');
    setPingResponse('');

    try {
      const pingData = {
        ping: true,
        timestamp: new Date().toISOString(),
        message: "Hello from Next.js! Rust binary, are you alive?"
      };

      const response = await fetch('/api/proxy', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(pingData),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();
      setPingResponse(JSON.stringify(result, null, 2));
    } catch (err) {
      setError(`Ping Error: ${err.message}`);
    } finally {
      setPingLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-black via-blue-900 to-purple-900">
      <Head>
        <title>Vercel Rust Template</title>
        <meta name="description" content="Minimal Next.js + Rust CLI template for Vercel" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          <header className="text-center mb-8">
            <h1 className="text-4xl font-bold text-white mb-4">
              Vercel Rust Template
            </h1>
            <p className="text-lg text-gray-300">
              Minimal Next.js + Rust CLI template with ping functionality
            </p>
          </header>

          <section className="bg-white/90 backdrop-blur-sm rounded-lg shadow-lg p-6">
            {/* Ping Section */}
            <div className="mb-6 pb-6 border-b border-gray-200">
              <h2 className="text-lg font-medium text-gray-900 mb-3">Quick Ping Test</h2>
              <p className="text-sm text-gray-600 mb-4">
                Test the connection to the Rust binary with a ping message
              </p>
              <button
                onClick={handlePing}
                disabled={pingLoading}
                className="bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {pingLoading ? 'Pinging...' : 'Ping Rust Binary'}
              </button>
              
              {pingResponse && (
                <div className="mt-4">
                  <h3 className="text-md font-medium text-gray-900 mb-2">Ping Response:</h3>
                  <pre className="bg-green-50 p-3 rounded-md border border-green-200 overflow-x-auto">
                    <code className="text-sm text-gray-800">{pingResponse}</code>
                  </pre>
                </div>
              )}
            </div>

            {/* Custom Message Section */}
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-2">
                  Custom Message to send to Rust binary:
                </label>
                <textarea
                  id="message"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  placeholder="Enter your custom message here..."
                  className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  rows={4}
                  required
                />
              </div>

              <button
                type="submit"
                disabled={loading || !input.trim()}
                className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {loading ? 'Processing...' : 'Send Custom Message'}
              </button>
            </form>

            {error && (
              <div className="mt-6 p-4 bg-red-50 border border-red-200 rounded-md">
                <p className="text-red-800">{error}</p>
              </div>
            )}

            {output && (
              <div className="mt-6">
                <h3 className="text-lg font-medium text-gray-900 mb-2">Response from Rust binary:</h3>
                <pre className="bg-gray-50 p-4 rounded-md border overflow-x-auto">
                  <code className="text-sm text-gray-800">{output}</code>
                </pre>
              </div>
            )}
          </section>

          <section className="mt-8 text-center">
            <button
              onClick={() => setShowHowItWorks(!showHowItWorks)}
              className="bg-purple-600 text-white py-3 px-6 rounded-lg hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 transition-colors font-medium"
            >
              {showHowItWorks ? 'Hide' : 'Show'} How it works
            </button>
            
            {showHowItWorks && (
              <div className="mt-6 bg-white/90 backdrop-blur-sm rounded-lg shadow-lg p-6 text-left">
                <h2 className="text-xl font-semibold text-gray-900 mb-4">How it works:</h2>
                <div className="space-y-3 text-gray-600">
                  <div>
                    <p className="font-semibold text-gray-800 mb-2">Ping Test:</p>
                    <ul className="list-disc list-inside space-y-1 ml-4">
                      <li>Click "Ping Rust Binary" to test the connection</li>
                      <li>Sends a structured ping message with timestamp</li>
                      <li>Displays the JSON response showing the binary is alive</li>
                    </ul>
                  </div>
                  <div>
                    <p className="font-semibold text-gray-800 mb-2">Custom Messages:</p>
                    <ul className="list-disc list-inside space-y-1 ml-4">
                      <li>Enter a custom message in the text area</li>
                      <li>Click "Send Custom Message" to process it</li>
                      <li>The message is sent to the Rust CLI binary via the <code className="bg-gray-100 px-1 rounded">/api/proxy</code> endpoint</li>
                      <li>The Rust binary processes the input and returns a JSON response</li>
                      <li>The response is displayed in the output area below</li>
                    </ul>
                  </div>
                </div>
              </div>
            )}
          </section>
        </div>
      </main>
    </div>
  );
}