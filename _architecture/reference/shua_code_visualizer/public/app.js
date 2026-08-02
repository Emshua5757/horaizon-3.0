document.addEventListener("DOMContentLoaded", async () => {
  const width = window.innerWidth;
  const height = window.innerHeight;

  const svg = d3.select("#graph-viewport")
    .attr("viewBox", [0, 0, width, height]);

  const container = svg.append("g");

  // Setup Zoom & Pan behavior
  const zoom = d3.zoom()
    .scaleExtent([0.1, 4])
    .on("zoom", (event) => {
      container.attr("transform", event.transform);
    });

  svg.call(zoom);

  // Define marker arrows for directed links
  svg.append("defs").append("marker")
    .attr("id", "arrow")
    .attr("viewBox", "0 -5 10 10")
    .attr("refX", 18)
    .attr("refY", 0)
    .attr("markerWidth", 6)
    .attr("markerHeight", 6)
    .attr("orient", "auto")
    .append("path")
    .attr("fill", "#475569")
    .attr("d", "M0,-5L10,0L0,5");

  // Color mapping based on language / cycle status
  const getColor = (d) => {
    if (d.is_cycle) return "hsl(0, 100%, 50%)"; // Red cycle glow
    switch (d.language.toLowerCase()) {
      case "typescript": return "hsl(190, 100%, 50%)"; // Cyan
      case "python": return "hsl(50, 100%, 50%)"; // Yellow
      case "rust": return "hsl(20, 100%, 50%)"; // Orange
      case "dart": return "hsl(215, 100%, 50%)"; // Blue
      case "c#": return "hsl(275, 100%, 50%)"; // Purple
      default: return "hsl(210, 10%, 60%)";
    }
  };

  try {
    const response = await fetch("/api/graph");
    const graphData = await response.json();

    const nodes = graphData.nodes;
    const links = graphData.links;

    // Simulation parameters
    const simulation = d3.forceSimulation(nodes)
      .force("link", d3.forceLink(links).id(d => d.id).distance(150))
      .force("charge", d3.forceManyBody().strength(-200))
      .force("center", d3.forceCenter(width / 2, height / 2))
      .force("collide", d3.forceCollide().radius(d => (d.centrality * 2) + 20));

    // Render links
    const link = container.append("g")
      .attr("class", "links")
      .selectAll("line")
      .data(links)
      .join("line")
      .attr("class", "link-line")
      .attr("marker-end", "url(#arrow)");

    // Render nodes
    const node = container.append("g")
      .attr("class", "nodes")
      .selectAll("g")
      .data(nodes)
      .join("g")
      .call(drag(simulation));

    // Append circles to nodes
    node.append("circle")
      .attr("class", "node-circle")
      .attr("r", d => (d.centrality * 1.5) + 6)
      .attr("fill", d => getColor(d))
      .attr("stroke", d => d.is_cycle ? "hsl(0, 100%, 70%)" : "rgba(255, 255, 255, 0.15)")
      .style("filter", d => `drop-shadow(0 0 8px ${getColor(d)})`);

    // Append labels to nodes
    node.append("text")
      .attr("class", "node-label")
      .attr("dy", d => (d.centrality * 1.5) + 18)
      .attr("text-anchor", "middle")
      .attr("fill", "#e2e8f0")
      .text(d => d.label);

    // Update positions on tick
    simulation.on("tick", () => {
      link
        .attr("x1", d => d.source.x)
        .attr("y1", d => d.source.y)
        .attr("x2", d => d.target.x)
        .attr("y2", d => d.target.y);

      node.attr("transform", d => `translate(${d.x},${d.y})`);
    });

    // Hover actions
    node.on("mouseover", (event, d) => {
      // Fade out unrelated items
      node.style("opacity", o => (o.id === d.id || isConnected(d, o) ? 1.0 : 0.15));
      link
        .style("stroke-opacity", l => (l.source.id === d.id || l.target.id === d.id ? 0.8 : 0.05))
        .style("stroke-width", l => (l.source.id === d.id || l.target.id === d.id ? 2.5 : 1.5))
        .style("stroke", l => (l.source.id === d.id ? "hsl(190, 100%, 50%)" : l.target.id === d.id ? "hsl(50, 100%, 50%)" : "#475569"));
    });

    node.on("mouseout", () => {
      node.style("opacity", 1.0);
      link
        .style("stroke-opacity", 0.25)
        .style("stroke-width", 1.5)
        .style("stroke", "#475569");
    });

    // Click actions (Show details panel)
    node.on("click", (event, d) => {
      showDetails(d, links);
    });

    // Helper functions
    function isConnected(a, b) {
      return links.some(l => 
        (l.source.id === a.id && l.target.id === b.id) || 
        (l.source.id === b.id && l.target.id === a.id)
      );
    }

    // Search functionality
    const searchInput = document.getElementById("search-input");
    searchInput.addEventListener("input", (e) => {
      const query = e.target.value.toLowerCase().trim();
      if (!query) {
        node.style("opacity", 1.0);
        link.style("opacity", 1.0);
        return;
      }
      
      node.style("opacity", d => d.id.toLowerCase().includes(query) || d.label.toLowerCase().includes(query) ? 1.0 : 0.15);
      link.style("opacity", l => l.source.id.toLowerCase().includes(query) || l.target.id.toLowerCase().includes(query) ? 0.6 : 0.05);
    });

  } catch (error) {
    console.error("[ERROR] Failed to render graph:", error);
  }

  // Drag behavior configuration
  function drag(simulation) {
    return d3.drag()
      .on("start", (event, d) => {
        if (!event.active) simulation.alphaTarget(0.3).restart();
        d.fx = d.x;
        d.fy = d.y;
      })
      .on("drag", (event, d) => {
        d.fx = event.x;
        d.fy = event.y;
      })
      .on("end", (event, d) => {
        if (!event.active) simulation.alphaTarget(0);
        d.fx = null;
        d.fy = null;
      });
  }

  // Display detail panel content
  function showDetails(node, allLinks) {
    const placeholder = document.getElementById("details-placeholder");
    const content = document.getElementById("details-content");

    placeholder.classList.add("hidden");
    content.classList.remove("hidden");

    document.getElementById("details-filename").textContent = node.id;
    document.getElementById("details-lang").textContent = node.language;
    document.getElementById("details-centrality").textContent = node.centrality.toFixed(1);
    
    const statusText = node.is_cycle ? "Circular Reference Detected" : "Stable";
    const statusEl = document.getElementById("details-status");
    statusEl.textContent = statusText;
    statusEl.className = "value " + (node.is_cycle ? "legend-dot cycle" : "badge");

    // Outgoing dependencies
    const depsUl = document.getElementById("details-dependencies");
    depsUl.innerHTML = "";
    const outgoing = allLinks.filter(l => l.source.id === node.id);
    if (outgoing.length === 0) {
      depsUl.innerHTML = "<li>None</li>";
    } else {
      outgoing.forEach(l => {
        const li = document.createElement("li");
        li.textContent = l.target.id;
        depsUl.appendChild(li);
      });
    }

    // Incoming dependents
    const depsInUl = document.getElementById("details-dependents");
    depsInUl.innerHTML = "";
    const incoming = allLinks.filter(l => l.target.id === node.id);
    if (incoming.length === 0) {
      depsInUl.innerHTML = "<li>None</li>";
    } else {
      incoming.forEach(l => {
        const li = document.createElement("li");
        li.textContent = l.source.id;
        depsInUl.appendChild(li);
      });
    }
  }
});
