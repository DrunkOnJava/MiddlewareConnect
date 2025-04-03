// src/components/CodeAnalyzer.jsx
import React, { useState, useEffect } from 'react';

function CodeAnalyzer({ code, language = 'javascript' }) {
  const [analysis, setAnalysis] = useState(null);
  const [analyzing, setAnalyzing] = useState(false);
  const [selectedRules, setSelectedRules] = useState({
    complexity: true,
    duplication: true,
    formatting: true,
    security: true,
    bestPractices: true
  });
  
  // Rules for different categories
  const rules = {
    complexity: [
      { id: 'long-function', description: 'Function is too long (over 30 lines)', regex: /function\s+\w+\([^)]*\)\s*{(?:[^{}]*|{[^{}]*})*}/g, check: match => match.split('\n').length > 30 },
      { id: 'deep-nesting', description: 'Deep nesting (more than 3 levels)', regex: /{[^{}]*{[^{}]*{[^{}]*{[^{}]*}/g },
      { id: 'too-many-params', description: 'Too many parameters (more than 4)', regex: /function\s+\w+\(([^)]*)\)/g, check: match => match.split(',').length > 4 }
    ],
    duplication: [
      { id: 'duplicate-code', description: 'Potential duplicated code blocks', custom: true }
    ],
    formatting: [
      { id: 'missing-semicolon', description: 'Missing semicolon', regex: /(?<!;|{|})\s*\n\s*(?!function|if|else|for|while|switch|case|break|continue|return|const|let|var|\/\/|\/\*|\*\/|{|}|;)/g },
      { id: 'trailing-whitespace', description: 'Trailing whitespace', regex: /[ \t]+$/gm },
      { id: 'inconsistent-indentation', description: 'Inconsistent indentation', custom: true }
    ],
    security: [
      { id: 'eval-usage', description: 'Usage of eval()', regex: /eval\s*\(/g },
      { id: 'innerhtml-usage', description: 'Direct innerHTML manipulation', regex: /\.innerHTML\s*=/g },
      { id: 'unsanitized-input', description: 'Potentially unsanitized input', regex: /document\.getElementById\([^)]*\)\.value/g }
    ],
    bestPractices: [
      { id: 'console-log', description: 'Console.log usage in production code', regex: /console\.log\(/g },
      { id: 'unused-variables', description: 'Potentially unused variables', custom: true },
      { id: 'var-usage', description: 'Usage of var instead of let/const', regex: /var\s+\w+/g }
    ]
  };
  
  // Custom analyzers
  const customAnalyzers = {
    'duplicate-code': (code) => {
      const issues = [];
      const lines = code.split('\n');
      const blockSize = 5; // Minimum block size to check for duplication
      
      const blocks = {};
      
      // Generate all blocks of 5+ lines
      for (let i = 0; i <= lines.length - blockSize; i++) {
        const blockContent = lines.slice(i, i + blockSize).join('\n').trim();
        if (blockContent.length > 50) { // Ignore short blocks
          blocks[blockContent] = blocks[blockContent] || [];
          blocks[blockContent].push(i + 1);
        }
      }
      
      // Find duplicates
      for (const [blockContent, positions] of Object.entries(blocks)) {
        if (positions.length > 1) {
          issues.push({
            line: positions[0],
            message: `Code block duplicated at lines: ${positions.join(', ')}`,
            severity: 'warning'
          });
        }
      }
      
      return issues;
    },
    
    'inconsistent-indentation': (code) => {
      const issues = [];
      const lines = code.split('\n');
      let prevIndent = -1;
      let prevIndentCount = 0;
      const indentCounts = {};
      
      lines.forEach((line, index) => {
        const trimmedLine = line.trimLeft();
        const indent = line.length - trimmedLine.length;
        
        if (trimmedLine.length === 0) return; // Skip empty lines
        
        // Count indentation
        if (indent > 0) {
          indentCounts[indent] = (indentCounts[indent] || 0) + 1;
        }
        
        // Check for inconsistent indent
        if (prevIndent >= 0 && Math.abs(indent - prevIndent) % 2 !== 0 && Math.abs(indent - prevIndent) !== 0) {
          issues.push({
            line: index + 1,
            message: `Inconsistent indentation: ${indent} spaces (previous: ${prevIndent})`,
            severity: 'info'
          });
        }
        
        prevIndent = indent;
        prevIndentCount = indent;
      });
      
      // Determine most common indent
      let mostCommonIndent = 0;
      let maxCount = 0;
      
      for (const [indent, count] of Object.entries(indentCounts)) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonIndent = parseInt(indent);
        }
      }
      
      // Overall inconsistent indent warning
      if (mostCommonIndent % 2 !== 0 && mostCommonIndent !== 1) {
        issues.push({
          line: 0,
          message: `File uses inconsistent indentation: most common is ${mostCommonIndent} spaces`,
          severity: 'info'
        });
      }
      
      return issues;
    },
    
    'unused-variables': (code) => {
      const issues = [];
      const declarations = [];
      
      // Find all variable declarations
      const declarationRegex = /(const|let|var)\s+(\w+)(?:\s*=\s*[^,;]+)?(?:,\s*(\w+)(?:\s*=\s*[^,;]+)?)*;/g;
      let match;
      
      while ((match = declarationRegex.exec(code)) !== null) {
        const varType = match[1];
        let varNames = [match[2]];
        
        // Handle multi-declarations
        if (match[3]) {
          const multiDeclaration = match[0];
          const additionalVars = multiDeclaration.match(/,\s*(\w+)(?:\s*=\s*[^,;]+)?/g);
          
          if (additionalVars) {
            additionalVars.forEach(varDecl => {
              const varName = varDecl.match(/,\s*(\w+)/)[1];
              varNames.push(varName);
            });
          }
        }
        
        varNames.forEach(varName => {
          declarations.push({
            name: varName,
            line: code.substring(0, match.index).split('\n').length,
            used: false
          });
        });
      }
      
      // Check for usage
      declarations.forEach(declaration => {
        // Create a regex that finds usage but not declaration
        const usageRegex = new RegExp(`[^a-zA-Z0-9_](${declaration.name})[^a-zA-Z0-9_=]`, 'g');
        let usageMatch;
        
        while ((usageMatch = usageRegex.exec(code)) !== null) {
          // Check if this is not just another declaration
          const lineContent = code.split('\n')[code.substring(0, usageMatch.index).split('\n').length - 1];
          if (!lineContent.includes(`const ${declaration.name}`) && 
              !lineContent.includes(`let ${declaration.name}`) && 
              !lineContent.includes(`var ${declaration.name}`)) {
            declaration.used = true;
            break;
          }
        }
        
        // Report unused variables
        if (!declaration.used) {
          issues.push({
            line: declaration.line,
            message: `Unused variable: ${declaration.name}`,
            severity: 'warning'
          });
        }
      });
      
      return issues;
    }
  };
  
  // Execute analysis
  const analyzeCode = () => {
    setAnalyzing(true);
    
    setTimeout(() => {
      try {
        const codeLines = code.split('\n');
        const results = [];
        
        // Run selected rule checks
        Object.entries(rules).forEach(([category, categoryRules]) => {
          if (selectedRules[category]) {
            categoryRules.forEach(rule => {
              if (rule.custom) {
                // Run custom analyzer
                const customIssues = customAnalyzers[rule.id](code);
                results.push(...customIssues.map(issue => ({
                  ...issue,
                  rule: rule.id,
                  category
                })));
              } else {
                // Run regex-based check
                let match;
                while ((match = rule.regex.exec(code)) !== null) {
                  // Skip if there's a custom check function and it returns false
                  if (rule.check && !rule.check(match[0])) continue;
                  
                  // Calculate line number
                  const lineNumber = code.substring(0, match.index).split('\n').length;
                  
                  results.push({
                    line: lineNumber,
                    message: rule.description,
                    severity: category === 'security' ? 'error' : 'warning',
                    rule: rule.id,
                    category
                  });
                }
              }
            });
          }
        });
        
        // Generate code quality metrics
        const metrics = calculateMetrics(code);
        
        setAnalysis({
          issues: results.sort((a, b) => a.line - b.line),
          metrics
        });
      } catch (error) {
        console.error('Error analyzing code:', error);
      } finally {
        setAnalyzing(false);
      }
    }, 500); // Give UI time to update
  };
  
  // Calculate code metrics
  const calculateMetrics = (code) => {
    const lines = code.split('\n');
    const nonEmptyLines = lines.filter(line => line.trim().length > 0);
    const commentLines = lines.filter(line => line.trim().startsWith('//') || line.trim().startsWith('/*') || line.trim().startsWith('*'));
    
    // Count functions
    const functionMatches = code.match(/function\s+\w+\s*\([^)]*\)/g) || [];
    const arrowFunctionMatches = code.match(/\([^)]*\)\s*=>\s*{/g) || [];
    
    return {
      totalLines: lines.length,
      nonEmptyLines: nonEmptyLines.length,
      commentLines: commentLines.length,
      functions: functionMatches.length + arrowFunctionMatches.length,
      commentRatio: Math.round((commentLines.length / nonEmptyLines.length) * 100) || 0,
      avgLineLength: Math.round(nonEmptyLines.reduce((sum, line) => sum + line.length, 0) / nonEmptyLines.length) || 0
    };
  };
  
  // Toggle rule categories
  const toggleRuleCategory = (category) => {
    setSelectedRules({
      ...selectedRules,
      [category]: !selectedRules[category]
    });
  };
  
  // Group issues by category
  const getIssuesByCategory = () => {
    if (!analysis || !analysis.issues) return {};
    
    return analysis.issues.reduce((grouped, issue) => {
      grouped[issue.category] = grouped[issue.category] || [];
      grouped[issue.category].push(issue);
      return grouped;
    }, {});
  };
  
  return (
    <div className="code-analyzer">
      <h3>Code Analysis</h3>
      
      <div className="analyzer-options">
        <div className="rule-toggles">
          {Object.keys(rules).map(category => (
            <label key={category} className="rule-toggle">
              <input
                type="checkbox"
                checked={selectedRules[category]}
                onChange={() => toggleRuleCategory(category)}
              />
              {category.charAt(0).toUpperCase() + category.slice(1)}
            </label>
          ))}
        </div>
        
        <button onClick={analyzeCode} disabled={analyzing}>
          {analyzing ? 'Analyzing...' : 'Analyze Code'}
        </button>
      </div>
      
      {analysis && (
        <div className="analysis-results">
          <div className="metrics-panel">
            <h4>Code Metrics</h4>
            <div className="metrics-grid">
              <div className="metric-item">
                <div className="metric-value">{analysis.metrics.totalLines}</div>
                <div className="metric-label">Total Lines</div>
              </div>
              <div className="metric-item">
                <div className="metric-value">{analysis.metrics.nonEmptyLines}</div>
                <div className="metric-label">Code Lines</div>
              </div>
              <div className="metric-item">
                <div className="metric-value">{analysis.metrics.commentLines}</div>
                <div className="metric-label">Comment Lines</div>
              </div>
              <div className="metric-item">
                <div className="metric-value">{analysis.metrics.commentRatio}%</div>
                <div className="metric-label">Comment Ratio</div>
              </div>
              <div className="metric-item">
                <div className="metric-value">{analysis.metrics.functions}</div>
                <div className="metric-label">Functions</div>
              </div>
              <div className="metric-item">
                <div className="metric-value">{analysis.metrics.avgLineLength}</div>
                <div className="metric-label">Avg. Line Length</div>
              </div>
            </div>
          </div>
          
          <div className="issues-panel">
            <h4>Issues ({analysis.issues.length})</h4>
            
            {Object.entries(getIssuesByCategory()).map(([category, issues]) => (
              <div key={category} className="issue-category">
                <h5>
                  {category.charAt(0).toUpperCase() + category.slice(1)} ({issues.length})
                </h5>
                
                <ul className="issues-list">
                  {issues.map((issue, index) => (
                    <li key={index} className={`issue-item ${issue.severity}`}>
                      <div className="issue-location">Line {issue.line}</div>
                      <div className="issue-message">{issue.message}</div>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
            
            {analysis.issues.length === 0 && (
              <p className="no-issues">No issues found</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default CodeAnalyzer;