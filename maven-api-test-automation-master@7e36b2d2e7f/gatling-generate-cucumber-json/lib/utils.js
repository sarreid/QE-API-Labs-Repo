'use strict';

const _ = require('lodash');
const fs = require('fs');
const path = require('path');
const jsonSchema = require('jsonschema');

/**
 * Retrieves the value of the specified environment variable.
 * Handles boolean values of 'true' and 'false' and returning the boolean typed value, and integer values
 * returning an integer value.
 * Otherwise, the value is returned as is.
 *
 * @param {string} name Environment variable name
 * @param {*} [defaultValue] Default value to be used
 * @return {*} Value, or undefined if not set
 */
function getEnvValue(name, defaultValue) {
    let value = process.env[name];
    if (_.isUndefined(value) || _.isNull(value) || (value === '')) {
        if (defaultValue !== undefined) {
            value = defaultValue;
        }
    }
    if (_.isString(value)) {
        if (value.toLowerCase() === 'true') {
            return true;
        } else if (value.toLowerCase() === 'false') {
            return false;
        } else if (_.isString(value) && (value === parseInt(value, 10).toString())) {
            return parseInt(value, 10);
        }
    }

    return value;
}

/**
 * Given a object, validates it against the supplied schema.
 *
 * If errors are present, errors are logged using console.error()
 *
 * @param {object} data Data object to be validated
 * @param {object} schema Schema to be used in validation
 * @return {boolean} Whether data obejct conforms to the specified schema
 */
function validateSchema(data, schema) {
    const errors = jsonSchema.validate(data, schema).errors;

    if (errors.length === 0) {
        return true;
    }

    // Log errors to console
    console.error();
    console.error('JSON schema validation errors:');
    errors.forEach(error => {
        console.error('\t' + error.toString());
    });
    console.error();

    return false;
}

/**
 * Given a parent directory, return list of directories present within the parent tree
 *
 * @param {string} parent Parent folder whose list of child folders are to be returned
 * @param {array[string]|boolean} folderList Current list of folders (if boolean, whether to recurse parent - true is default)
 * @returns {array[string]} List of child folders present within parent
 */
function getFolders(parent, folderList) {

    let recurse = false;

    if (folderList === false || folderList === true) {
        recurse = folderList;
        folderList = [];
    } else {
        folderList = folderList || [];
        recurse = true;
    }

    fs.readdirSync(parent).forEach(file => {
        const folder = path.join(parent, file);
        if (isDirectory(folder)) {
            folderList.push(folder);
            if (recurse) {
                folderList = getFolders(folder, folderList);
            }
        }
    });

    return folderList;
}

/**
 * Given a parent directory, return list of files present within the parent tree, relative to parent
 *
 * @param {string} parent Parent folder whose list of child folders are to be returned
 * @param {array[string]} fileList Current list of files
 * @returns {array[string]} List of child files present within parent
 */
function getFiles(parent, fileList, relative) {

    relative = relative || '.';
    fileList = fileList || [];

    fs.readdirSync(parent).forEach(file => {
        const item = path.join(parent, file);
        const relativeItem = path.join(relative, file);
        if (isDirectory(item)) {
            fileList = getFiles(item, fileList, relativeItem);
        } else if (isFile(item)) {
            fileList.push(relativeItem);
        }
    });

    return fileList;
}

/**
 * Loads a file containing valid JSON and returns JavaScript object/array
 *
 * @param {string} file Relative file name to load
 * @returns {array|object} Contents of JSON file as object/array
 */
function loadJson(file) {
    const raw = fs.readFileSync(file);
    return JSON.parse(raw);
}

/**
 * Checks whether a path exists and is a directory
 *
 * @param {string} item path to file/folder
 * @return {boolean} Whether item exists and is a directory
 */
function isDirectory(item) {
    if (!fs.existsSync(item)) {
        return false;
    }
    const stat = fs.statSync(item);
    return stat.isDirectory();
}

/**
 * Checks whether a path exists and is a file
 *
 * @param {string} item path to file
 * @return {boolean} Whether item exists and is a file
 */
function isFile(item) {
    if (!fs.existsSync(item)) {
        return false;
    }
    const stat = fs.statSync(item);
    return stat.isFile();
}

/**
 * Creates a directory
 *
 * @param {string} path Path of directory to be created
 */
function mkdir(path) {
    console.log(`Creating folder '${path}'`);
    fs.mkdirSync(path, { recursive: true });
}

/**
 * Deletes a file
 *
 * @param {string} path Path of file to be deleted
 */
function rm(path) {
    console.log(`Deleting file '${path}'`);
    fs.unlinkSync(path);
}

/**
 * Removes a directory, which may or may not, be empty
 *
 * @param {string} path Path of directory to be removed
 */
function rmdir(path) {
    console.log(`Deleting folder '${path}'`);
    fs.rmdirSync(path, { recursive: true });
}

module.exports = {
    getEnvValue,
    isDirectory,
    isFile,
    getFiles,
    getFolders,
    loadJson,
    mkdir,
    rm,
    rmdir,
    validateSchema
};
