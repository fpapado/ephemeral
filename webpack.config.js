const webpack = require('webpack');
const path = require('path');
const merge = require('webpack-merge');
const md5 = require('md5');

const CleanWebpackPlugin = require('clean-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const HTMLWebpackPlugin = require('html-webpack-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const NameAllModulesPlugin = require('name-all-modules-plugin');
const OfflinePlugin = require('offline-plugin');
const WebpackPwaManifest = require('webpack-pwa-manifest');
const DashboardPlugin = require('webpack-dashboard/plugin');
const {BundleAnalyzerPlugin} = require('webpack-bundle-analyzer');

var isProd = process.env.NODE_ENV === 'production';

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
    events: true,
    minify: true
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

// Bundle analyzer config
let bundlePlugin = new BundleAnalyzerPlugin({
  analyzerMode: 'static',
  openAnalyzer: false,
  reportFilename: 'bundle-analysis.html'
});

// -- Common Config --
var common = {
  entry: {
    main: './src/index.js',
    vendor: ['pouchdb-browser', 'pouchdb-authentication', 'leaflet']
  },
  output: {
    path: path.join(__dirname, 'dist'),

    // Hash as appropriate for production; based on chunks etc.
    filename: isProd ? '[name]-[chunkhash].js' : '[name]-[hash].js'
  },
  devtool: '#source-map',
  plugins: [
    new CleanWebpackPlugin(['dist']),

    // Give modules a deterministic name for better long-term caching:
    // https://github.com/webpack/webpack.js.org/issues/652#issuecomment-273023082
    new webpack.NamedModulesPlugin(),

    // Give dynamically `import()`-ed scripts a deterministic name for better
    // long-term caching. Solution adapted from:
    new webpack.NamedChunksPlugin(
      chunk =>
        chunk.name
          ? chunk.name
          : md5(chunk.mapModules(m => m.identifier()).join()).slice(0, 10)
    ),

    new HTMLWebpackPlugin({
      // using .ejs prevents other loaders causing errors
      template: 'src/index.ejs',
      // inject details of output file at end of body
      inject: 'body'
    }),

    new webpack.optimize.CommonsChunkPlugin({
      name: ['vendor'],
      minChunks: Infinity
      // (with more entries, this ensures that no other module
      // goes into the vendor chunk)
      // TODO: add a common entry point if needed
    }),

    //// Extract runtime code so updates don't affect app-code caching:
    // https://webpack.js.org/guides/caching
    new webpack.optimize.CommonsChunkPlugin({
      name: 'runtime'
    }),

    // Give deterministic names to all webpacks non-"normal" modules
    // https://medium.com/webpack/predictable-long-term-caching-with-webpack-d3eee1d3fa31
    new NameAllModulesPlugin(),

    pwaPlugin
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
            cacheDirectory: true,
            presets: [
              [
                'env',
                {
                  debug: true,
                  modules: false,
                  useBuiltIns: true,
                  targets: {
                    browsers: ['> 1%', 'last 2 versions', 'Firefox ESR']
                  }
                }
              ]
            ],
            plugins: ['syntax-dynamic-import']
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

if (!isProd) {
  console.log('Building for dev...');
  module.exports = merge(common, {
    plugins: [
      // Prevents compilation errors causing the hot loader to lose state
      new webpack.NoEmitOnErrorsPlugin(),
      new DashboardPlugin()
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
                debug: true,
                pathToMake: './bin/unbuffered-elm-make'
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

if (isProd) {
  console.log('Building for prod...');
  module.exports = merge(common, {
    plugins: [
      new CopyWebpackPlugin([
        {
          from: 'src/assets'
        }
      ]),
      new webpack.DefinePlugin({
        'process.env': {
          NODE_ENV: JSON.stringify('production')
        }
      }),
      new UglifyJsPlugin({
        sourceMap: true,
        uglifyOptions: {
          compress: {
            warnings: false
          },
          mangle: {
            safari10: true
          },
          output: {
            comments: false
          }
        }
      }),
      offlinePlugin,
      bundlePlugin
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
              loader: 'elm-webpack-loader',
              options: {
                pathToMake: './bin/unbuffered-elm-make'
              }
            }
          ]
        }
      ]
    }
  });
}
