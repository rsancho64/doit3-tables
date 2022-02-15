[**Original**](https://levelup.gitconnected.com/build-an-express-api-with-sequelize-cli-and-express-router-963b6e274561)

Building a full-fledged Node.js API can be done fairly easily using Sequelize for object relational mapping and Express as the framework for a server, and Express' Router class is a useful tool for handling your app's routes in a modular, organized way.

In this walkthrough, we'll build a Sequelize project including associations and seed data, then use Express Router to define the routes for our server. Finally, we'll deploy our app to [Heroku](https://www.heroku.com/) to create a publicly accessible API.

# creating the sequelize app

We'll move as quickly as possible through our Sequelize setup in order to get to using Router --- but we'll include notes along the way for those who want to know more about using the Sequelize CLI or defining Sequelize associations.

Let's start by installing Postgres, Sequelize, and the [Sequelize CLI](https://github.com/sequelize/cli) in a new project folder we'll call `express-api-using-router`:

```bash
git init
npm init -y
npm install sequelize pg && npm install --save-dev sequelize-cli
```

Let's also add a `.gitignore` file to ease deployment later:

```bash
echo "
/node_modules
.DS_Store
.env" >> .gitignore
```
Next we will initialize a Sequelize project, then open the directory in our code editor:

```bash
npx sequelize-cli init
code .
```

> To learn more about the Sequelize CLI commands below, see: [**Getting Started with Sequelize CLI**](https://medium.com/@brunopgalvao/getting-started-with-sequelize-cli-c33c797f05c6)

Let's configure our Sequelize project to work w a mySql db. Find `config.json` in  `/config`  and change the code to look like this:

```json
{
  "development": {
    "database": "pp_api_dev",
    "dialect":  "mysql"
  },
  "test": {
    "database": "projects_api_test",
    "dialect":  "mysql"
  },
  "production": {
    "use_env_variable": "DATABASE_URL",
    "dialect": "mysql",
    "dialectOptions": {
      "ssl": {
        "rejectUnauthorized": false
      }
    }
  }
}
```

> Note: For `production` we use `use_env_variable` and `DATABASE_URL` ; we are going to deploy this app to [Heroku](https://www.heroku.com/). Heroku is smart enough to replace `DATABASE_URL` with the production db, which we'll see in action later.

Now we can tell Sequelize CLI to create the db:

```bash
npx sequelize-cli db:create
```

# defining models; seeding data 

Our demoapp will associate users with certain projects. Let's start by creating a `User` model using the Sequelize CLI:

```bash
npx sequelize-cli model:generate --name User --attributes firstName:string,lastName:string,email:string,password:string
```

Running `model:generate` automatically creates both a model file and a migration with the attributes we've specified. Now we can execute the migration to create the `Users` table in our database:

```bash
npx sequelize-cli db:migrate
```

Now let's create a seed file:

```bash
npx sequelize-cli seed:generate --name users
```

You will see a new file in the`/seeders` directory. In that file, paste the code below, which will create entries in your database for three users:

```javascript
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('Users', [{
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@doe.com',
      password: '123456789',
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      firstName: 'John',
      lastName: 'Smith',
      email: 'john@smith.com',
      password: '123456789',
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      firstName: 'John',
      lastName: 'Stone',
      email: 'john@stone.com',
      password: '123456789',
      createdAt: new Date(),
      updatedAt: new Date()
    }], {});
  },  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('Users', null, {});
  }
};
```

We've named all three users "John"... just because. Now let's add a `Project` model so that we can give these Johns something to do:

```bash
npx sequelize-cli model:generate --name Project --attributes title:string,imageUrl:string,description:text,userId:integer
```

Now we'll create associations between the two models.

> To learn more about creating Sequelize associations, see: [**Creating Sequelize Associations with Sequelize CLI**](https://medium.com/@brunopgalvao/creating-sequelize-associations-with-the-sequelize-cli-tool-d83caa902233)

First, find `user.js` in `/models` and replace the code with this:

```javascript
module.exports = (sequelize, DataTypes) => {
  const Project = sequelize.define('Project', {
    title:       DataTypes.STRING,
    imageUrl:    DataTypes.STRING,
    description: DataTypes.TEXT,
    userId:      DataTypes.INTEGER
  }, {});
  Project.associate = function (models) {
    // associations can be defined here
    Project.belongsTo(models.User, {
      foreignKey: 'userId',
      onDelete: 'CASCADE'
    })
  };
  return Project;
};
```

Now find `project.js` in the same directory and replace the code with this:

```
module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    firstName: DataTypes.STRING,
    lastName:  DataTypes.STRING,
    email:     DataTypes.STRING,
    password:  DataTypes.STRING
  }, {});
  User.associate = function (models) {
    // associations can be defined here
    User.hasMany(models.Project, {
      foreignKey: 'userId'
    })
  };
  return User;
};
```

Finally, we'll add the foreign key to the newest migration file. You should see two files in your `/migrations` subdirectory. Look for the filename that ends with `create-project.js` and change the code inside to the below:

```
'use strict';
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.createTable('Projects', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      title: {
        type: Sequelize.STRING
      },
      imageUrl: {
        type: Sequelize.STRING
      },
      description: {
        type: Sequelize.TEXT
      },
      userId: {
        type: Sequelize.INTEGER,
        onDelete: 'CASCADE',
        references: {
          model: 'Users',
          key: 'id',
          as: 'userId',
        }
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  down: (queryInterface, Sequelize) => {
    return queryInterface.dropTable('Projects');
  }
};
```

Perform the migration to create the Projects table in the Postgres db:

```
npx sequelize-cli db:migrate
```

Let's create a seed file for Projects:

```
npx sequelize-cli seed:generate --name projects
```

You'll see a new file in your `/seeders` subdirectory that ends with `projects.js`. Change the code in that file to the following:

```
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('Projects', [{
      title: 'Project 1',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/6a/JavaScript-logo.png',
      description: 'This project was built using Vanilla JavaScript, HTML, and CSS',
      userId: 1,
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      title: 'Project 2',
      imageUrl: 'https://www.stickpng.com/assets/images/584830f5cef1014c0b5e4aa1.png',
      description: 'This project was built using React & a 3rd-party API.',
      userId: 3,
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      title: 'Project 3',
      imageUrl: 'https://expressjs.com/images/express-facebook-share.png',
      description: 'This project was built using Express & React.',
      userId: 2,
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      title: 'Project 4',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/16/Ruby_on_Rails-logo.png',
      description: 'This project was built using Rails & React.',
      userId: 1,
      createdAt: new Date(),
      updatedAt: new Date()
    }], {});
  },  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('Projects', null, {});
  }
};
```

Now we'll run both seed files to add our users and our projects to the database:

```
npx sequelize-cli db:seed:all
```

Now let's drop into `psql` to make sure the data exists on the database:

```
psql projects_api_development
SELECT * FROM "Users" JOIN "Projects" ON "Users".id = "Projects"."userId";
```

# Setting up Express {#d624 .ix .iy .dw .ce .iz .ja .jb .id .jc .jd .je .ih .jf .jg .jh .ji .jj .jk .jl .jm .jn .jo .jp .jq .jr .js .et}

Great, our Sequelize project is ready to roll. Now we can incorporate Express and set up routes to serve our data. First, let's install Express, along with [nodemon](https://nodemon.io/) to monitor changes in our files and [body-parser](https://www.npmjs.com/package/body-parser) to handle information from user requests:

```
npm install --save express 
npm install -D nodemon 
npm install body-parser
```

Now let's set up the architecture by creating two new directories and three new files:

```
mkdir routes controllers
touch server.js  routes/index.js controllers/index.js
```

Now we'll modify the `package.json` file to support nodemon. Also, we can facilitate development by creating a new command: `npm db:reset`. We'll set this up to drop the db, create db, run migrations, and seed anew whenever we need!

```
....
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "nodemon server.js",
    "db:reset": "npx sequelize-cli db:drop && npx sequelize-cli db:create && npx sequelize-cli db:migrate && npx sequelize-cli db:seed:all"
  },
....
```

Now let's start building our Express app. Inside the `server.js` file, add the following:

```
const express = require('express');
const routes = require('./routes');
const bodyParser = require('body-parser')
const PORT = process.env.PORT || 3000;
const app = express();
app.use(bodyParser.json());
app.use('/api', routes);
app.listen(PORT, () => console.log(`Listening on port: ${PORT}`))
```

Here we've created a basic Express server set to listen on port 3000. But rather than defining the routes in this file, we've added `app.use('/api', routes)` to refer any requests beginning with `api` to the `index.js` file in our `/routes` subdirectory.

> To learn more about basic Express setup with Sequelize, see:\ [**Sequelize CLI and Express**](/sequelize-cli-and-express-fb3ddefb9786)

# Using Express Router with controllers 

We'll start by setting up the root route. Open the `./routes/index.js` file and add the following code:

```
const { Router } = require('express');
const controllers = require('../controllers');
const router = Router();router.get('/', (req, res) => res.send('This is root!'))
module.exports = router
```

Test the route:

```
npm start
```

Now open the root endpoint in your browser: <http://localhost:3000/api/>

Good, our Express app works, but now we need to make it deliver data from Sequelize. We'll do this by creating a controller to handle all of our logic --- our pathways for creating new users and projects, updating users, etc.

Open `./controllers/index.js` and add the following:

```
const { User } = require('../models');const createUser = async (req, res) => {
    try {
        const user = await User.create(req.body);
        return res.status(201).json({
            user,
        });
    } catch (error) {
        return res.status(500).json({ error: error.message })
    }
}module.exports = {
    createUser
}
```

Here we've incorporated the `User` model we defined in Sequelize create a new database entry based on the information in the API request. To make this work, we'll create a route on our server to connect the request with the controller:

In `./routes/index.js`, add a new line after your "This is root!" route:

```
router.post('/users', controllers.createUser)
```

from now we use a REST client like [Postman](https://www.postman.com/) (or [Insomnia](https://insomnia.rest/))

[install postman on deb11](https://www.how2shout.com/linux/2-ways-to-install-postman-on-debian-11-bullseye-or-10-buster/)

- [x] Using Postman direct `POST` request at `/api/users` to the `createUser` function in our controller (`POST` method to send the following JSON body to <http://localhost:3000/api/users>:

```
{
  "firstName": "Jane",
  "lastName":  "Smith",
  "email":     "jane@smith.com",
  "password":  "123456789"
}
```

Now we finally have a user who's not named John! More importantly, we've used Router and a controller to deliver data from Sequelize to our API users. 

We can use the same strategy to connect any Sequelize query to an Express endpoint.

> To learn more about customizing Sequelize queries, see: [**Using the Sequelize CLI and Querying**](/using-the-sequelize-cli-and-querying-4ba8d0ac4314)

- [x] Let's create another controller method to grab all the users from the db along with their associated projects. Make these changes to `./controllers/index.js`:

```js
const { User, Project } = require('../models');
const createUser = async (req, res) => {
    try {
        const user = await User.create(req.body);
        return res.status(201).json({
            user,
        });
    } catch (error) {
        return res.status(500).json({ error: error.message })
    }
}
const getAllUsers = async (req, res) => {
    try {
        const users = await User.findAll({
            include: [
                {
                    model: Project
                }
            ]
        });
        return res.status(200).json({ users });
    } catch (error) {
        return res.status(500).send(error.message);
    }
}
module.exports = {
    createUser,
    getAllUsers
}
```

You'll notice we've added the `Project` model to our requirement at the top, and the new `getAllUsers` function specifies that a user's projects should be included.
We've also added the new function to `module.exports`

Now we just need to add a route in `./routes/index.js` to direct traffic toward this function:

```
router.get('/users', controllers.getAllUsers)
```

Test the route by opening <http://localhost:3000/api/users> in your browser or by doing a `GET` request in Postman.

- [x] Now let's add the ability to find a specific user with their associated projects. Add the following function to `./controllers/index.js`:

```
const getUserById = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await User.findOne({
            where: { id: id },
            include: [
                {
                    model: Project
                }
            ]
        });
        if (user) {
            return res.status(200).json({ user });
        }
        return res.status(404).send('User with the specified ID does not exists');
    } catch (error) {
        return res.status(500).send(error.message);
    }
}
```

Don't forget to add `getUserById` to the export:

```
module.exports = {
    createUser,
    getAllUsers,
    getUserById
}
```

Now we'll use the new function to make a new route in
`./routes/index.js`:

```
router.get('/users/:id', controllers.getUserById)
```

Here we've added a route parameter, `:id`. Our controller function pulls this info from `req.params` to find a specific user. Let's test it at <http://localhost:3000/api/users/2>!

So we can now create users, show all users, and show a specific user. How about **updating** a user and deleting a user? Let's add a new function for each in `./controllers/index.js`:

```
const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const [updated] = await User.update(req.body, {
            where: { id: id }
        });
        if (updated) {
            const updatedUser = await User.findOne({ where: { id: id } });
            return res.status(200).json({ user: updatedUser });
        }
        throw new Error('User not found');
    } catch (error) {
        return res.status(500).send(error.message);
    }
};
const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const deleted = await User.destroy({
            where: { id: id }
        });
        if (deleted) {
            return res.status(204).send("User deleted");
        }
        throw new Error("User not found");
    } catch (error) {
        return res.status(500).send(error.message);
    }
};
```

Make sure your exports are updated:

```
module.exports = {
    createUser,
    getAllUsers,
    getUserById,
    updateUser,
    deleteUser
}
```

Let's add our routes in `./routes/index.js`:

```
router.put(   '/users/:id', controllers.updateUser)
router.delete('/users/:id', controllers.deleteUser)
```

Now let's test the update route by making a `PUT` request in Postman at <http://localhost:3000/api/users/3>. The request body should look something like this:

```
{
    "firstName": "John",
    "lastName":  "Smith",
    "email":     "john.smith@smith.com",
    "password":  "superPass1"
}
```

Finally, test delete with a `DEL` request at the same URL.

Now we're down to only *two* Johns! More importantly, we've just built a full CRUD JSON API in Express, Sequelize, and Mysql using Express Router!

# @@@@@

# Logging 

This is a good point to integrate better logging. Right now, if we check our terminal when we hit the <http://localhost:3000/api/users/2> endpoint, we'll see the raw SQL that was executed. For debugging purposes and overall better logging let's install an Express middleware called [morgan](https://www.npmjs.com/package/morgan):

```
npm install morgan
```

Add the following to your `server.js` file:

```
const logger = require('morgan');
app.use(logger('dev'))
```

Let's see the result:

```
npm start
open http://localhost:3000/api/users/2
```

You should now see in your terminal something like this:

```
GET /api/users/2 304 104.273 ms
```

That's morgan!

# Deploying to Heroku 

Now let's deploy our app to [Heroku](https://devcenter.heroku.com/articles/heroku-cli#download-and-install) to make a publicly accessible API.

Heroku will use `package.json` to build our app from the Git repository, so we need to update that file as follows:

```
...
"scripts": {
    "test":     "echo \"Error: no test specified\" && exit 1",
    "start":    "node server.js",
    "dev":      "nodemon server.js",
    "db:reset": "npx sequelize-cli db:drop && npx sequelize-cli db:create && npx sequelize-cli db:migrate && npx sequelize-cli db:seed:all"
  },
...
```

Now, when Heroku starts your remote server with the `npm start` script, it will run your code in standard Node. (We can still use nodemon locally by running `npm run dev`.)

> You'll need to install the Heroku CLI in your terminal for the following steps. [**Find out how here.**](https://devcenter.heroku.com/articles/heroku-cli)

Let's use the Heroku CLI to set up a new app. Replace both instances of `your-heroku-app-name` in the code below with whatever name you like, then run these three commands in your terminal:

1.  [`heroku create your-heroku-app-name`
2.  [`heroku buildpacks:set heroku/nodejs`
3.  [`heroku addons:create heroku-postgresql:hobby-dev --app=your-heroku-app-name`

Now Heroku is prepared to build a Node.js app with a PostgreSQL database. Let's commit our code to Git (make sure you're on the `master` branch!) and upload the repository to Heroku:

1.  [`git status`]{#ec39}
2.  [`git commit -am "add any pending changes"`]
3.  [`git push heroku master`]

Heroku will build a production version of the same app that we've been running in our local environment. Now we just need to tell Heroku to execute our migrations and seed files: 

1.  [`heroku run npx sequelize-cli db:migrate`
2.  [`heroku run npx sequelize-cli db:seed:all`

> Having issues? Debug with the Heroku command `heroku logs --tail` to see what\'s happening on the Heroku server.

Now you can test endpoints on your remote server by replacing "your-heroku-app-name" below with whatever name you used earlier:

-   [https://your-heroku-app-name.herokuapp.com/api/users]
-   [https://your-heroku-app-name.herokuapp.com/api/users/1]

There are those three Johns again! Try using Postman to create, update, and delete users the same way we did above.

Excellent! Now you can access your new Express API from anywhere on the planet. Next, try [defining your own Sequelize associations](https://medium.com/@brunopgalvao/creating-sequelize-associations-with-the-sequelize-cli-tool-d83caa902233) making [custom Sequelize queries](https://medium.com/@brunopgalvao/using-the-sequelize-cli-and-querying-4ba8d0ac4314), and adding [more robust seed data](/getting-started-with-sequelize-cli-using-faker-824b3f4c4cfe) --- or ensure the reliability of your app by [**building an Express API with unit testing**](https://medium.com/@brunopgalvao/building-an-express-api-with-sequelize-cli-and-unit-testing-882c6875ed59)

> This article was co-authored with [Jeremy Rose](https://www.linkedin.com/in/jeremy-r-rose), software engineer, editor, and writer based in NYC.

# More info on Sequelize CLI and Express: 

-   [[Getting Started with Sequelize CLI](https://medium.com/@brunopgalvao/getting-started-with-sequelize-cli-c33c797f05c6)
-   [[Using Sequelize CLI and Querying](https://medium.com/@brunopgalvao/using-the-sequelize-cli-and-querying-4ba8d0ac4314)
-   [[Creating Sequelize Associations with Sequelize CLI](https://medium.com/@brunopgalvao/creating-sequelize-associations-with-the-sequelize-cli-tool-d83caa902233)
-   [[Getting Started with Sequelize CLI using Faker](/getting-started-with-sequelize-cli-using-faker-824b3f4c4cfe)
-   [[Sequelize CLI and Express](https://medium.com/@brunopgalvao/sequelize-cli-and-express-fb3ddefb9786)
-   [[Building an Express API with Sequelize CLI and Unit Testing!](https://medium.com/@brunopgalvao/building-an-express-api-with-sequelize-cli-and-unit-testing-882c6875ed59)

