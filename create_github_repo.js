#!/usr/bin/env node

import { ChildProcess, spawn } from 'child_process';
import readline from 'readline';

// Main function
async function main() {
  console.log("GitHub Repository Creation Script");
  console.log("=================================");
  
  // Get token from command line argument
  const token = process.argv[2];
  if (!token) {
    console.error("Error: GitHub token is required");
    console.error("Usage: node create_github_repo.js <github_token>");
    process.exit(1);
  }

  // Set up environment for the MCP server
  const env = {
    ...process.env,
    GITHUB_PERSONAL_ACCESS_TOKEN: token
  };

  // Start the GitHub MCP server
  console.log("\nStarting GitHub MCP server...");
  
  // Use npx with the package name directly
  console.log("Using npx to run the server");
  
  const server = spawn('npx', ['-y', '@modelcontextprotocol/server-github'], {
    env,
    stdio: ['pipe', 'pipe', 'pipe']
  });

  // Send a create repository request
  const createRepoRequest = {
    jsonrpc: "2.0",
    id: 1,
    method: "tools/call",
    params: {
      name: "create_repository",
      arguments: {
        name: "MiddlewareConnect",
        description: "MiddlewareConnect: A Swift framework for LLM integration and document processing",
        private: false,
        autoInit: true
      }
    }
  };

  // Wait for server initialization
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Send the request to the server
  server.stdin.write(JSON.stringify(createRepoRequest) + '\n');
  
  // Handle server output
  let responseData = '';
  server.stdout.on('data', (data) => {
    responseData += data.toString();
    
    try {
      // Check if we have a complete JSON response
      const lines = responseData.trim().split('\n');
      for (const line of lines) {
        if (line.trim()) {
          const response = JSON.parse(line);
          if (response.id === 1) {
            if (response.error) {
              console.error("Error creating repository:", response.error.message);
            } else {
              console.log("\nRepository created successfully!");
              console.log(JSON.stringify(response.result, null, 2));
            }
            // Close the server
            server.kill();
            process.exit(0);
          }
        }
      }
    } catch (err) {
      // Incomplete JSON, continue collecting data
    }
  });

  // Handle errors
  server.stderr.on('data', (data) => {
    console.error(`Server error: ${data.toString()}`);
  });

  // Handle server exit
  server.on('close', (code) => {
    if (code !== 0) {
      console.error(`Server exited with code ${code}`);
    }
  });
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
