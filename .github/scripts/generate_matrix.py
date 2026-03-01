#!/usr/bin/env python3
"""
Generate GitHub Wiki and HTML table from Class Skillz.txt
"""

import json
from pathlib import Path

def parse_skillz_file(file_path):
    """Parse the Skillz.txt file and return headers and data rows"""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Get headers and filter out "n/u" entries
    all_headers = lines[0].strip().split('\t')
    headers = []
    header_indices = []  # Keep track of which indices to keep
    
    for i, header in enumerate(all_headers):
        if header != 'n/u':
            headers.append(header)
            header_indices.append(i)
    
    data = []
    for line in lines[1:]:
        line = line.strip()
        if line:
            row = line.split('\t')
            # Only keep columns that correspond to non-n/u headers
            filtered_row = [row[0]]  # Keep skill name
            for i in header_indices:
                if i + 1 < len(row):  # +1 because skill name is at index 0
                    filtered_row.append(row[i + 1])
                else:
                    filtered_row.append('')
            data.append(filtered_row)
    
    return headers, data

def should_remove_skill(skill_name):
    """Check if a skill should be removed"""
    if skill_name.startswith('Skill') and skill_name[5:].isdigit():
        return True
    return False

def transform_skill_name(skill_name):
    """Transform skill names according to the mapping"""
    skill_mapping = {
        'Unarmed': 'Unarmed/Fangs',
        'Dodging': 'Dodging/Scales',
        'Fire': 'Fire/Combat',
        'Air': 'Air/Subtlety',
        'Water': 'Water/Frost/Poison',
        'Earth': 'Earth/Assassinate',
        'Body': 'Body/Blood',
        'Dark': 'Dark/Undead'
    }
    return skill_mapping.get(skill_name, skill_name)

def generate_markdown_table(headers, data):
    """Generate GitHub Wiki formatted markdown table"""
    
    # Filter out unwanted skills and transform skill names
    filtered_data = []
    removed_count = 0
    for row in data:
        skill_name = row[0]
        if should_remove_skill(skill_name):
            removed_count += 1
            continue
        filtered_data.append([transform_skill_name(skill_name)] + row[1:])
    
    # Start building markdown
    md_content = """# Class Skills Matrix

This table shows skill proficiencies for different classes.

**Legend:**
- **N**: Novice
- **E**: Expert
- **M**: Master
- **G**: Grandmaster
- **S**: Supreme
- **=**: Not available

"""
    
    # Create the table header
    md_content += "| Skill / Class | " + " | ".join(headers) + " |\n"
    md_content += "|" + "---|" * (len(headers) + 1) + "\n"
    
    # Add data rows
    for row in filtered_data:
        skill_name = row[0]
        padded_row = row[1:] + [''] * (len(headers) - len(row[1:]))
        md_content += f"| {skill_name} | " + " | ".join(padded_row) + " |\n"
    
    return md_content, filtered_data, removed_count

def generate_html_table(headers, data):
    """Generate interactive HTML table with filtering"""
    
    # Filter data for HTML (same as markdown)
    filtered_data = []
    for row in data:
        skill_name = row[0]
        if should_remove_skill(skill_name):
            continue
        filtered_data.append([transform_skill_name(skill_name)] + row[1:])
    
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Class Skills Matrix</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #24292e;
            max-width: 100%;
            overflow-x: auto;
            padding: 20px;
            margin: 0;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 20px;
        }
        h1 {
            border-bottom: 2px solid #eaecef;
            padding-bottom: 0.3em;
            color: #0366d6;
            margin-top: 0;
        }
        .legend {
            background: #f6f8fa;
            border-radius: 6px;
            padding: 15px 20px;
            margin: 20px 0;
            border: 1px solid #e1e4e8;
        }
        .legend h3 {
            margin-top: 0;
            margin-bottom: 10px;
            color: #24292e;
        }
        .legend ul {
            list-style: none;
            padding: 0;
            margin: 0;
            display: flex;
            flex-wrap: wrap;
            gap: 25px;
        }
        .legend li {
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        .badge {
            display: inline-block;
            width: 24px;
            height: 24px;
            line-height: 24px;
            text-align: center;
            border-radius: 4px;
            font-weight: bold;
            font-size: 14px;
        }
        .badge-novice { background-color: #e7f3ff; color: #0366d6; border: 1px solid #0366d6; }
        .badge-expert { background-color: #d4edda; color: #155724; border: 1px solid #28a745; }
        .badge-master { background-color: #fff3cd; color: #856404; border: 1px solid #ffc107; }
        .badge-grandmaster { background-color: #cce5ff; color: #004085; border: 1px solid #007bff; }
        .badge-supreme { background-color: #e0ccff; color: #4a1b8a; border: 1px solid #6f42c1; }
        .badge-nochange { background-color: #e2e3e5; color: #383d41; border: 1px solid #6c757d; }
        
        .filter-container {
            margin: 20px 0;
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }
        #skillFilter {
            padding: 10px 12px;
            font-size: 14px;
            border: 2px solid #e1e4e8;
            border-radius: 6px;
            flex: 1;
            min-width: 250px;
            transition: border-color 0.3s;
        }
        #skillFilter:focus {
            outline: none;
            border-color: #0366d6;
        }
        .filter-btn {
            padding: 10px 20px;
            background-color: #28a745;
            color: white;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            transition: background-color 0.3s;
        }
        .filter-btn:hover {
            background-color: #218838;
        }
        .filter-btn.reset {
            background-color: #6c757d;
        }
        .filter-btn.reset:hover {
            background-color: #5a6268;
        }
        .stats {
            background-color: #f6f8fa;
            padding: 10px 15px;
            border-radius: 6px;
            margin: 10px 0;
            font-size: 14px;
            color: #586069;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
            font-size: 14px;
            background-color: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        th, td {
            border: 1px solid #e1e4e8;
            padding: 10px 12px;
            text-align: center;
        }
        th {
            background-color: #f6f8fa;
            font-weight: 600;
            position: sticky;
            top: 0;
            z-index: 10;
            color: #24292e;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        tr:nth-child(even) {
            background-color: #fafbfc;
        }
        tr:hover {
            background-color: #f0f3f5;
        }
        td:first-child {
            font-weight: 600;
            text-align: left;
            position: sticky;
            left: 0;
            background-color: white;
            z-index: 5;
            box-shadow: 2px 0 5px -2px rgba(0,0,0,0.1);
        }
        tr:hover td:first-child {
            background-color: #f0f3f5;
        }
        .value-cell {
            font-weight: 500;
            border-radius: 4px;
        }
        .value-N { background-color: #e7f3ff; color: #0366d6; }
        .value-E { background-color: #d4edda; color: #155724; }
        .value-M { background-color: #fff3cd; color: #856404; }
        .value-G { background-color: #cce5ff; color: #004085; }
        .value-S { background-color: #e0ccff; color: #4a1b8a; }
        .value-\\= { background-color: #e2e3e5; color: #383d41; }
        
        .class-filter {
            margin: 20px 0;
            padding: 15px;
            background-color: #f6f8fa;
            border-radius: 6px;
        }
        .class-filter h4 {
            margin-top: 0;
            margin-bottom: 10px;
        }
        .class-checkboxes {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            max-height: 200px;
            overflow-y: auto;
            padding: 10px;
            background-color: white;
            border-radius: 4px;
            border: 1px solid #e1e4e8;
        }
        .class-checkbox {
            display: flex;
            align-items: center;
            gap: 5px;
            min-width: 150px;
        }
        .export-btn {
            background-color: #0366d6;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            margin-left: auto;
        }
        .export-btn:hover {
            background-color: #0353b0;
        }
        .select-all {
            margin-bottom: 10px;
        }
        .select-all button {
            padding: 5px 10px;
            background-color: #0366d6;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            margin-right: 10px;
        }
        .removed-note {
            font-size: 12px;
            color: #6c757d;
            margin-top: 5px;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏆 Class Skills Matrix</h1>
        
        <div class="legend">
            <h3>📊 Legend</h3>
            <ul>
                <li><span class="badge badge-novice">N</span> Novice</li>
                <li><span class="badge badge-expert">E</span> Expert</li>
                <li><span class="badge badge-master">M</span> Master</li>
                <li><span class="badge badge-grandmaster">G</span> Grandmaster</li>
                <li><span class="badge badge-supreme">S</span> Supreme</li>
                <li><span class="badge badge-nochange">=</span> Not available</li>
            </ul>
        </div>
        
        <div class="filter-container">
            <input type="text" id="skillFilter" placeholder="🔍 Filter by skill name...">
            <button class="filter-btn" onclick="filterTable()">Apply Filter</button>
            <button class="filter-btn reset" onclick="resetFilter()">Reset</button>
            <button class="export-btn" onclick="exportToCSV()">📥 Export to CSV</button>
        </div>
        
        <div class="class-filter">
            <h4>🎯 Filter by Class</h4>
            <div class="select-all">
                <button onclick="selectAllClasses(true)">Select All</button>
                <button onclick="selectAllClasses(false)">Deselect All</button>
            </div>
            <div id="classCheckboxes" class="class-checkboxes">
                <!-- Will be populated by JavaScript -->
            </div>
        </div>
        
        <div id="stats" class="stats">
            Showing <span id="visibleCount">0</span> of <span id="totalCount">0</span> skills
        </div>
        
        <div style="overflow-x: auto; max-height: 600px;">
            <table id="skillsTable">
                <thead>
                    <tr id="tableHeader">
                    </tr>
                </thead>
                <tbody id="tableBody">
                </tbody>
            </table>
        </div>
    </div>
    
    <script>
        const headers = """ + json.dumps(headers) + """;
        const data = """ + json.dumps([[row[0], *row[1:]] for row in filtered_data]) + """;
        
        let classFilters = {};
        headers.forEach((_, index) => {
            classFilters[index] = true;
        });
        
        function renderClassCheckboxes() {
            const container = document.getElementById('classCheckboxes');
            container.innerHTML = headers.map((header, index) => `
                <label class="class-checkbox">
                    <input type="checkbox" class="class-filter-checkbox" data-index="${index}" checked>
                    <span>${header}</span>
                </label>
            `).join('');
            
            document.querySelectorAll('.class-filter-checkbox').forEach(checkbox => {
                checkbox.addEventListener('change', function() {
                    const index = parseInt(this.dataset.index);
                    classFilters[index] = this.checked;
                    filterTable();
                });
            });
        }
        
        function selectAllClasses(select) {
            document.querySelectorAll('.class-filter-checkbox').forEach(cb => {
                cb.checked = select;
                const index = parseInt(cb.dataset.index);
                classFilters[index] = select;
            });
            filterTable();
        }
        
        function renderTable(filterText = '') {
            const headerRow = document.getElementById('tableHeader');
            const tbody = document.getElementById('tableBody');
            
            // Get visible classes
            const visibleClasses = headers.filter((_, index) => classFilters[index]);
            const visibleIndices = headers.map((_, index) => classFilters[index] ? index : -1).filter(i => i !== -1);
            
            // Render header with only visible classes
            headerRow.innerHTML = '<th>Skill / Class</th>' + 
                visibleClasses.map(h => `<th>${h}</th>`).join('');
            
            // Filter data by skill name
            const filteredData = filterText 
                ? data.filter(row => row[0].toLowerCase().includes(filterText.toLowerCase()))
                : data;
            
            // Render body with only visible classes
            tbody.innerHTML = filteredData.map(row => {
                const skillName = row[0];
                const allValues = row.slice(1);
                const visibleValues = visibleIndices.map(i => allValues[i] || '');
                
                return '<tr>' +
                    `<td>${skillName}</td>` +
                    visibleValues.map(v => {
                        const valueClass = v ? `value-${v.replace('=', '\\\\=')}` : '';
                        return `<td class="value-cell ${valueClass}">${v || ''}</td>`;
                    }).join('') +
                '</tr>';
            }).join('');
            
            // Update stats
            document.getElementById('visibleCount').textContent = filteredData.length;
            document.getElementById('totalCount').textContent = data.length;
        }
        
        function filterTable() {
            const filterText = document.getElementById('skillFilter').value;
            renderTable(filterText);
        }
        
        function resetFilter() {
            document.getElementById('skillFilter').value = '';
            selectAllClasses(true);
        }
        
        function exportToCSV() {
            const visibleIndices = headers.map((_, index) => classFilters[index] ? index : -1).filter(i => i !== -1);
            const visibleHeaders = visibleIndices.map(i => headers[i]);
            
            let csv = 'Skill / Class,' + visibleHeaders.join(',') + '\\n';
            
            const filterText = document.getElementById('skillFilter').value;
            const filteredData = filterText 
                ? data.filter(row => row[0].toLowerCase().includes(filterText.toLowerCase()))
                : data;
            
            filteredData.forEach(row => {
                const skillName = row[0];
                const values = visibleIndices.map(i => row[i + 1] || '');
                csv += '"' + skillName + '",' + values.join(',') + '\\n';
            });
            
            const blob = new Blob([csv], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'class-skills-matrix.csv';
            a.click();
        }
        
        // Initial render
        renderClassCheckboxes();
        renderTable();
    </script>
</body>
</html>"""
    
    return html_content

def main():
    # Define paths
    repo_root = Path(__file__).parent.parent.parent
    skillz_file = repo_root / "Data/Tables/Class Skillz.txt"
    wiki_output = repo_root / "Class-Skills-Matrix.md"
    html_output = repo_root / "Class-Skills-Matrix.html"
    
    # Parse and generate
    try:
        headers, data = parse_skillz_file(skillz_file)
        
        print(f"📊 Original classes: Found {len(headers)} valid classes (removed 'n/u' entries)")
        
        # Generate markdown
        md_content, filtered_data, removed_skills = generate_markdown_table(headers, data)
        with open(wiki_output, 'w', encoding='utf-8') as f:
            f.write(md_content)
        
        # Generate HTML
        html_content = generate_html_table(headers, data)
        with open(html_output, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"✅ Successfully generated files:")
        print(f"   📊 Markdown: {wiki_output}")
        print(f"   🌐 HTML: {html_output}")
        print(f"   📈 Statistics:")
        print(f"      - Classes: {len(headers)}")
        print(f"      - Skills kept: {len(filtered_data)}")
        print(f"      - Skills removed (SkillN): {removed_skills}")
        
    except FileNotFoundError:
        print(f"❌ Error: Could not find {skillz_file}")
        print("Make sure 'Class Skillz.txt' is in the repository root")
        raise
    except Exception as e:
        print(f"❌ Error processing file: {e}")
        raise

if __name__ == "__main__":
    main()
