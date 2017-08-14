const webpack = require('webpack');
const path = require('path');
const merge = require('webpack-merge');

const CopyWebpackPlugin = require('copy-webpack-plugin');
const HTMLWebpackPlugin = require('html-webpack-plugin');
const OfflinePlugin = require('offline-plugin');
const WebpackPwaManifest = require('webpack-pwa-manifest');
const DashboardPlugin = require('webpack-dashboard/plugin');

var TARGET_ENV =
  process.env.npm_lifecycle_event === 'prod' ? 'production' : 'development';

var filename = TARGET_ENV == 'production' ? '[name]-[hash].js' : 'index.js';

// -- Offline Plugin --
let offlinePlugin = new OfflinePlugin({
  safeToUseOptionalCaches: true,

  caches: {
    main: [':rest:'],
    additional: [':externals:']
  },

  externals: [
    'https://unpkg.com/leaflet@1.2.0/dist/leaflet.css',
    'https://unpkg.com/tachyons@4.7.0/css/tachyons.min.css',
    'https://fonts.googleapis.com/css?family=Pacifico'
  ],

  ServiceWorker: {
    navigateFallbackURL: '/',
    events: true
  }
});

// -- PWA Manifest --
let pwaPlugin = new WebpackPwaManifest({
  name: 'Ephemeral',
  short_name: 'Ephemeral',
  description: 'Save words and translations when you see them!',
  background_color: '#A5DBF7',
  theme_color: '#A5DBF7',
  icons: [
    {
      src: path.resolve('src/assets/icon.png'),
      sizes: [96, 128, 192, 256, 384, 512] // multiple sizes
    }
  ]
});

// -- Common Config --
var common = {
  entry: './src/index.js',
  output: {
    path: path.join(__dirname, 'dist'),
    // add hash when building for production
    filename: filename
  },
  plugins: [
    new HTMLWebpackPlugin({
      // using .ejs prevents other loaders causing errors
      template: 'src/index.ejs',
      // inject details of output file at end of body
      inject: 'body'
    }),
    pwaPlugin,
    new DashboardPlugin()
  ],
  resolve: {
    modules: [path.join(__dirname, 'src'), 'node_modules'],
    extensions: ['.js', '.elm', '.css', '.scss', '.png']
  },
  module: {
    // noParse: /(lie|pouchdb|pouchdb-browser)\.js$/,
    rules: [
      {
        test: /\.html$/,
        exclude: /node_modules/,
        loader: 'file-loader?name=[name].[ext]'
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            // env: automatically determines the Babel plugins you need based on your supported environments
            presets: ['env']
          }
        }
      },
      {
        test: /\.scss$/,
        exclude: [/elm-stuff/, /node_modules/],
        loaders: ['style-loader', 'css-loader', 'sass-loader']
      },
      {
        test: /\.css$/,
        exclude: [/elm-stuff/, /node_modules/],
        loaders: ['style-loader', 'css-loader']
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'url-loader',
        options: {
          limit: 10000,
          mimetype: 'application/font-woff'
        }
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'file-loader'
      },
      {
        test: /\.(jpe?g|png|gif|svg)$/i,
        loader: 'file-loader'
      }
    ]
  }
};

if (TARGET_ENV === 'development') {
  console.log('Building for dev...');
  module.exports = merge(common, {
    plugins: [
      // Suggested for hot-loading
      new webpack.NamedModulesPlugin(),
      // Prevents compilation errors causing the hot loader to lose state
      new webpack.NoEmitOnErrorsPlugin()
      // , offlinePlugin
    ],
    resolve: {
      alias: {
        config: path.join(__dirname, 'config/development.js')
      }
    },
    module: {
      rules: [
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: [
            {
              loader: 'elm-hot-loader'
            },
            {
              loader: 'elm-webpack-loader',
              // add Elm's debug overlay to output
              options: {
                debug: true
              }
            }
          ]
        }
      ]
    },
    devServer: {
      inline: true,
      stats: 'errors-only',
      contentBase: path.join(__dirname, 'src/assets')
    }
  });
}

if (TARGET_ENV === 'production') {
  console.log('Building for prod...');
  module.exports = merge(common, {
    plugins: [
      new CopyWebpackPlugin([
        {
          from: 'src/assets'
        }
      ]),
      new webpack.optimize.UglifyJsPlugin(),
      offlinePlugin
    ],
    resolve: {
      alias: {
        config: path.join(__dirname, 'config/production.js')
      }
    },
    module: {
      rules: [
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: [
            {
              loader: 'elm-webpack-loader'
            }
          ]
        }
      ]
    }
  });
}
