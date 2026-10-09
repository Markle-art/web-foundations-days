const loadButton = document.querySelector("#load-users");
const filterInput = document.querySelector("#filter-input");
const statusMessage = document.querySelector("#status");
const usersList = document.querySelector("#users-list");

let users = [];

async function loadUsers() {
    loadButton.disabled = true;
    filterInput.disabled = true;
    statusMessage.textContent = "Loading users...";
    usersList.textContent = "";

    try {
        const response = await fetch(
            "https://jsonplaceholder.typicode.com/users"
        );

        if (!response.ok) {
            throw new Error(`Request failed with status ${response.status}`);
        }

        users = await response.json();

        renderUsers(users);

        filterInput.disabled = false;
        statusMessage.textContent = `Successfully loaded ${users.length} users.`;
    } catch (error) {
        users = [];
        renderUsers(users);
        statusMessage.textContent =
            "Unable to load users. Please try again.";
        console.error("Error loading users:", error);
    } finally {
        loadButton.disabled = false;
    }
}

function renderUsers(list) {
    usersList.textContent = "";

    list.forEach(user => {
        const listItem = document.createElement("li");

        const name = document.createElement("h3");
        name.textContent = user.name;

        const email = document.createElement("p");
        email.textContent = `Email: ${user.email}`;

        const city = document.createElement("p");
        city.textContent = `City: ${user.address.city}`;

        const company = document.createElement("p");
        company.textContent = `Company: ${user.company.name}`;

        listItem.append(name, email, city, company);
        usersList.appendChild(listItem);
    });

    if (list.length === 0 && users.length > 0) {
        const message = document.createElement("li");
        message.textContent = "No users match your filter.";
        usersList.appendChild(message);
    }
}

loadButton.addEventListener("click", loadUsers);

filterInput.addEventListener("input", () => {
    const query = filterInput.value.trim().toLowerCase();

    const filteredUsers = users.filter(user =>
        user.name.toLowerCase().includes(query)
    );

    renderUsers(filteredUsers);
});