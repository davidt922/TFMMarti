const path = require('path')
const CopyWebpackPlugin = require('copy-webpack-plugin')

module.exports = {
  entry: {
    dialog: './app/scripts/dialog.js',
    orderBook:'./app/scripts/orderBook.js',
    market: './app/scripts/market.js',
    onWindowsLoad: './app/scripts/onWindowsLoad.js',
    paymentRequest: './app/scripts/paymentRequest.js',
    accountDialog: './app/scripts/accountDialog.js',
  },
  mode: 'production',
  output: {
    path: path.resolve(__dirname, 'build'),
    filename: '[name].js'
  },
  plugins: [
    // Copy our app's index.html to the build folder.
    new CopyWebpackPlugin([
      { from: './app/index.html', to: 'index.html' }
    ])
  ],
  devtool: 'source-map',
  module: {
    rules: [
      { test: /\.s?css$/, use: [ 'style-loader', 'css-loader', 'sass-loader' ] },
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        loader: 'babel-loader',
        query: {
          presets: ['env'],
          plugins: ['transform-react-jsx', 'transform-object-rest-spread', 'transform-runtime']
        }
      }
    ]
  }
}
