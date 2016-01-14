# benchmark

## Why

This project main purpose was to find general parameters and differences between 3G, 2G, Wi-fi and other types of network.

## Not implemented

You have to specify and implement 2 URLs:

```ObjC
NSString * const baseURL = @"#";
NSString * const baseURLSocket = @"#";
```

server at baseURL must respond to the following request:

```
/test?data_length=<bytes>&wait=<miliseconds>
```

server at baseURLSocket must respond to JSON

```json
{ 
"data_length":<bytes>,
"wait":<miliseconds>
}
```

response data can be any data of `data_length`. response is sent after waiting for the specified period.
