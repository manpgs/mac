const urls = new Map();

async function populateList() {
  const res = await fetch("sitemap.xml");
  if (!res.ok) return;
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(await res.text(), "text/xml");
  for (const loc of xmlDoc.getElementsByTagName("loc")) {
    const url = loc.textContent;
    const [section, name] = url.split("/").slice(-2).map(decodeURIComponent);
    if (!name || !/^[0-9]/.test(section)) continue;
    const option = document.createElement("option");
    const label = `${name}(${section})`;
    option.textContent = label;
    dataList.append(option);
    urls.set(label, url);
  }
}

const dataList = document.createElement("datalist");
dataList.id = "pages";

const input = document.createElement("input");
input.id = "page";
input.type = "search";
input.placeholder = "page";
input.setAttribute("list", dataList.id);
input.onchange = () => (form.action = urls.get(input.value) ?? "");
input.onmouseenter = () => {
  input.onmouseenter = null;
  populateList(dataList);
};

const label = document.createElement("label");
label.textContent = "man ";
label.append(input);

const form = document.createElement("form");
form.append(dataList);
form.append(label);
form.onsubmit = (event) => {
  event.preventDefault();
  location.href = form.action;
};

document.querySelector("header").append(form);
