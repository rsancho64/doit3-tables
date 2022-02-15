# bash script
# recipe: https://levelup.gitconnected.com/build-an-express-api-with-sequelize-cli-and-express-router-963b6e274561

rm -Rf config/ controllers/ migrations/ models/ 
rm -Rf node_modules
rm -Rf routes/ seeders/  
sync && sleep 2

rm -Rf .git* package* 

npm init -y
npm install --save mysql2 sequelize pg
npm install -D sequelize-cli
npm install -D nodemon 
npm install --save body-parser # to handle info from user requests
npm install --save express 

git init
echo "
/node_modules
.env
" >> .gitignore

npx sequelize-cli init

cat << CONFIG..CONFIG.JSON > config/config.json
{
  "development": {
    "username": "root",
    "password": "bea",
    "database": "3t",
    "host":     "127.0.0.1",
    "dialect":  "mysql"
  },

  "test": {
    "database": "pp_api_test",
    "dialect":  "mysql"
  },

  "production": {
    "use_env_variable": "DATABASE_URL",
    "dialect":          "mysql",
    "dialectOptions": {
      "ssl": {
        "rejectUnauthorized": false
      }
    }
  }
}
CONFIG..CONFIG.JSON

# DB ----------------

mysql -u root -pbea -e "drop database if exists 3t;"
npx sequelize-cli db:create

# models n seed data ---------------- 

## Cliente model:
npx sequelize-cli model:generate --name Cliente \
--attributes firstName:string,lastName:string
#--attributes firstName:string,lastName:string,email:string,password:string
npx sequelize-cli db:migrate

# npx sequelize-cli seed:generate --name clientes
cat << SEEDERS..0.USERS.JS > seeders/0-clientes.js
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('Clientes', [{
      firstName: 'John',
      lastName:  'Doe',
      //email:     'john@doe.com',
      //password:  '123456789',
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      firstName: 'John',
      lastName:  'Smith',
      //email:     'john@smith.com',
      //password:  '123456789',
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      firstName: 'John',
      lastName:  'Stone',
      //email:     'john@stone.com',
      //password:  '123456789',
      createdAt: new Date(),
      updatedAt: new Date()
    }], {});
  },  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('Clientes', null, {});
  }
};
SEEDERS..0.USERS.JS

## Venta model:
npx sequelize-cli model:generate --name Venta \
--attributes title:string,modelo:text,clienteId:integer
npx sequelize-cli db:migrate

## set associations between the two models ( cliente n ventas )

cat << MODELS..USER.JS > models/cliente.js
'use strict';
const {
  Model
} = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  const Venta = sequelize.define('Venta', {
    title:       DataTypes.STRING,
    //imageUrl:    DataTypes.STRING,
    modelo:      DataTypes.TEXT,
    clienteId:   DataTypes.INTEGER
  }, {});
  Venta.associate = function (models) {
    // associations can be defined here
    Venta.belongsTo(models.Cliente, {
      foreignKey: 'clienteId',
      onDelete: 'CASCADE'
    })
  };
  return Venta;
};
MODELS..USER.JS

cat << MODELS..PROJECT.JS > models/venta.js
'use strict';
const {
  Model
} = require('sequelize');

// module.exports = (sequelize, DataTypes) => {
//   class Venta extends Model {
//     static associate(models) {
//       // define association here
//     }
//   }
//   Venta.init({
//     title: DataTypes.STRING,
//     //imageUrl: DataTypes.STRING,
//     modelo: DataTypes.TEXT,
//     clienteId: DataTypes.INTEGER
//   }, {
//     sequelize,
//     modelName: 'Venta',
//   });
//   return Venta;
// };

module.exports = (sequelize, DataTypes) => {
  const Cliente = sequelize.define('Cliente', {
    firstName: DataTypes.STRING,
    lastName:  DataTypes.STRING,
    //email:     DataTypes.STRING,
    //password:  DataTypes.STRING
  }, {});
  Cliente.associate = function (models) {
    // associations can be defined here
    Cliente.hasMany(models.Venta, {
      foreignKey: 'clienteId'
    })
  };
  return Cliente;
};
MODELS..PROJECT.JS

# npx sequelize-cli seed:generate --name ventas
cat << MIGRATIONS..0-CREATE-PROJECT.JS > migrations/0-create-venta.js
'use strict';
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.createTable('Ventas', {
      id: {
        allowNull:     false,
        autoIncrement: true,
        primaryKey:    true,
        type: Sequelize.INTEGER
      },
      title: {
        type: Sequelize.STRING
      },
      //imageUrl: {
      //  type: Sequelize.STRING
      //},
      modelo: {
        type: Sequelize.TEXT
      },
      clienteId: {
        type: Sequelize.INTEGER,
        onDelete: 'CASCADE',
        references: {
          model: 'Clientes',
          key:   'id',
          as:    'clienteId',
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
    return queryInterface.dropTable('Ventas');
  }
};
MIGRATIONS..0-CREATE-PROJECT.JS

npx sequelize-cli db:migrate

# npx sequelize-cli seed:generate --name ventas
cat << SEEDERS..0.PROJECTS.JS > seeders/0-ventas.js
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('Ventas', [{
      title: 'Venta 1',
      //imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/6a/JavaScript-logo.png',
      modelo: 'Ford Mustang',
      clienteId: 1,
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      title: 'Venta 2',
      //imageUrl: 'https://www.stickpng.com/assets/images/584830f5cef1014c0b5e4aa1.png',
      modelo: 'Jaguar X3',
      clienteId: 3,
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      title: 'Venta 3',
      //imageUrl: 'https://expressjs.com/images/express-facebook-share.png',
      modelo: 'Ford Sierra',
      clienteId: 2,
      createdAt: new Date(),
      updatedAt: new Date()
    },
    {
      title: 'Venta 4',
      //imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/16/Ruby_on_Rails-logo.png',
      modelo: 'MB C200',
      clienteId: 1,
      createdAt: new Date(),
      updatedAt: new Date()
    }], {});
  },  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('Ventas', null, {});
  }
};
SEEDERS..0.PROJECTS.JS

npx sequelize-cli db:seed:all

# test seeding:
mysql -u root -pbea -e "\
    use 3t;

--  SELECT * FROM 
--  Clientes JOIN Ventas 
--  ON Clientes.id = Ventas.clienteId;

    SELECT Clientes.id as 'clienteID', Ventas.title as 'Venta' FROM 
    Clientes JOIN Ventas 
    ON Clientes.id = Ventas.clienteId;
"

# use Express; set up routes ------------------------------------------

mkdir routes controllers
touch server.js  routes/index.js controllers/index.js

# update package.json
cat << PJS > package.json
{
  "name": "exp-api",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "nodemon server.js",
    "db:reset": "npx sequelize-cli db:drop && npx sequelize-cli db:create && npx sequelize-cli db:migrate && npx sequelize-cli db:seed:all"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "body-parser": "^1.19.1",
    "express": "^4.17.2",
    "mysql2": "^2.3.3",
    "pg": "^8.7.3",
    "sequelize": "^6.16.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.15",
    "sequelize-cli": "^6.4.1"
  }
}
PJS

cat << ROUTES..INDEX.JS > routes/index.js
const { Router } = require('express');
const controllers = require('../controllers');
const router = Router();router.get('/', (req, res) => res.send('HOME! '))

router.post('/clientes',     controllers.createCliente)
router.get( '/clientes',     controllers.getAllClientes)
router.get( '/clientes/:id', controllers.getClienteById)

module.exports = router
ROUTES..INDEX.JS

cat << SERVER.JS > server.js
const express = require('express');
const routes = require('./routes');
const bodyParser = require('body-parser')
const PORT = process.env.PORT || 3000;
const app = express();
app.use(bodyParser.json());
app.use('/api', routes);
app.listen(PORT, () => console.log('escucha en puerto' , PORT))
SERVER.JS

cat << CONTROLLERS..INDEX.JS > controllers/index.js
const { Cliente, Venta } = require('../models');

const createCliente = async (req, res) => {
    try {
        const cliente = await Cliente.create(req.body);
        return res.status(201).json({
            cliente,
        });
    } catch (error) {
        return res.status(500).json({ error: error.message })
    }
}

const getAllClientes = async (req, res) => {
    try {
        const clientes = await Cliente.findAll({
            include: [
                {
                    model: Venta
                }
            ]
        });
        return res.status(200).json({ clientes });
    } catch (error) {
        return res.status(500).send(error.message);
    }
}

const getClienteById = async (req, res) => {
    try {
        const { id } = req.params;
        const cliente = await Cliente.findOne({
            where: { id: id },
            include: [
                {
                    model: Venta
                }
            ]
        });
        if (cliente) {
            return res.status(200).json({ cliente });
        }
        return res.status(404).send('Cliente with the specified ID does not exists');
    } catch (error) {
        return res.status(500).send(error.message);
    }
}
module.exports = {
    createCliente,
    getAllClientes,
    getClienteById
}
CONTROLLERS..INDEX.JS 
rm .git* -Rf
