const fs = require('fs');

const phase2Css = `
/* ==========================================================================
   PHASE 2: AI MEETING MEMORY & CROSS-MEETING INTELLIGENCE STYLES
   ========================================================================== */

/* 1. AI Meeting Search */
.search-header-container {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  padding: 20px;
  margin-bottom: 20px;
}

.search-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
  margin-bottom: 14px;
}

.search-input-wrap i {
  position: absolute;
  left: 16px;
  font-size: 18px;
  color: var(--primary);
}

.search-bar-input {
  width: 100%;
  padding: 14px 16px 14px 46px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  color: var(--text-main);
  font-size: 14px;
  outline: none;
  transition: all 0.2s ease;
}

.search-bar-input:focus {
  border-color: var(--primary);
  box-shadow: 0 0 12px rgba(99, 102, 241, 0.25);
}

.search-controls-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.search-mode-group {
  display: inline-flex;
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 2px;
}

.search-mode-chip {
  background: transparent;
  border: none;
  color: var(--text-dim);
  font-size: 12px;
  font-weight: 600;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.search-mode-chip.active {
  background: var(--primary);
  color: #ffffff;
}

.search-filters-group {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.search-select-filter {
  background: var(--bg-surface);
  color: var(--text-main);
  border: 1px solid var(--border-color);
  border-radius: 6px;
  font-size: 12px;
  padding: 6px 10px;
  outline: none;
}

.recent-searches-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 14px;
  flex-wrap: wrap;
}

.recent-pill {
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid var(--border-color);
  border-radius: 20px;
  padding: 4px 12px;
  font-size: 11.5px;
  color: var(--text-dim);
  cursor: pointer;
  transition: all 0.2s ease;
}

.recent-pill:hover {
  background: rgba(99, 102, 241, 0.15);
  color: var(--primary);
  border-color: rgba(99, 102, 241, 0.3);
}

.ai-synthesis-card {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.1), rgba(168, 85, 247, 0.08));
  border: 1px solid rgba(99, 102, 241, 0.25);
  border-radius: var(--radius-md);
  padding: 16px;
  margin-bottom: 20px;
}

.search-hit-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  padding: 16px;
  margin-bottom: 12px;
  transition: all 0.2s ease;
}

.search-hit-card:hover {
  border-color: rgba(99, 102, 241, 0.4);
  transform: translateY(-2px);
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.2);
}

.search-hit-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
  flex-wrap: wrap;
  gap: 8px;
}

.relevance-badge {
  font-size: 11px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 12px;
  background: rgba(16, 185, 129, 0.15);
  color: #10b981;
  border: 1px solid rgba(16, 185, 129, 0.3);
}

.search-hit-excerpt {
  font-size: 13.5px;
  line-height: 1.6;
  color: var(--text-main);
  background: rgba(255, 255, 255, 0.02);
  border-left: 3px solid var(--primary);
  padding: 8px 12px;
  border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
  margin: 8px 0 12px;
}

/* 2. Meeting Comparison Matrix */
.compare-selector-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 20px;
}

@media (max-width: 768px) {
  .compare-selector-grid {
    grid-template-columns: 1fr;
  }
}

.compare-meeting-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  padding: 16px;
}

.compare-matrix-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 16px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.compare-matrix-table th {
  background: rgba(255, 255, 255, 0.03);
  text-align: left;
  padding: 12px 16px;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  color: var(--text-dim);
  border-bottom: 1px solid var(--border-color);
}

.compare-matrix-table td {
  padding: 14px 16px;
  border-bottom: 1px solid var(--border-color);
  font-size: 13px;
  line-height: 1.5;
  vertical-align: top;
}

.status-badge-matrix {
  font-size: 11px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 6px;
  display: inline-block;
  margin-bottom: 4px;
}

.status-progressed { background: rgba(16, 185, 129, 0.15); color: #10b981; }
.status-changed { background: rgba(59, 130, 246, 0.15); color: #3b82f6; }
.status-same { background: rgba(107, 114, 128, 0.15); color: #9ca3af; }
.status-risk { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
.status-not-mentioned { background: rgba(245, 158, 11, 0.15); color: #f59e0b; }

/* 3. Meeting Memory Engine */
.memory-nav-tabs {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 10px;
  margin-bottom: 16px;
  scrollbar-width: thin;
}

.memory-tab-btn {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  color: var(--text-dim);
  border-radius: 20px;
  padding: 6px 14px;
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
  cursor: pointer;
  transition: all 0.2s ease;
}

.memory-tab-btn.active {
  background: var(--primary);
  color: #fff;
  border-color: var(--primary);
}

.memory-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
}

.memory-item-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  padding: 16px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 10px;
  transition: all 0.2s ease;
}

.memory-item-card:hover {
  border-color: var(--primary);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.25);
}

.memory-meta-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 11px;
  color: var(--text-dim);
}

/* 4. Company Knowledge Base */
.kb-upload-dropzone {
  border: 2px dashed rgba(99, 102, 241, 0.35);
  background: rgba(99, 102, 241, 0.04);
  border-radius: var(--radius-lg);
  padding: 30px 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-bottom: 24px;
}

.kb-upload-dropzone:hover {
  border-color: var(--primary);
  background: rgba(99, 102, 241, 0.08);
}

.fmt-badge {
  display: inline-block;
  font-size: 10px;
  font-weight: 800;
  padding: 2px 6px;
  border-radius: 4px;
  text-transform: uppercase;
  background: rgba(255, 255, 255, 0.06);
  color: var(--text-dim);
  margin: 0 3px;
}

/* 5. Scope Switcher in AI Chat */
.chat-scope-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  padding: 8px 12px;
  margin-bottom: 12px;
  flex-wrap: wrap;
  gap: 10px;
}

.scope-chips-group {
  display: inline-flex;
  gap: 6px;
}

.scope-chip {
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  color: var(--text-dim);
  font-size: 11.5px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.scope-chip.active {
  background: var(--primary);
  color: #fff;
  border-color: var(--primary);
}

.citation-pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background: rgba(99, 102, 241, 0.12);
  color: var(--primary);
  border: 1px solid rgba(99, 102, 241, 0.25);
  border-radius: 4px;
  padding: 2px 6px;
  font-size: 11px;
  font-weight: 600;
  margin: 4px 4px 0 0;
  cursor: pointer;
  transition: all 0.15s ease;
}

.citation-pill:hover {
  background: var(--primary);
  color: #fff;
}
`;

fs.appendFileSync('style.css', phase2Css, 'utf8');
console.log('Successfully appended Phase 2 styles to style.css!');

