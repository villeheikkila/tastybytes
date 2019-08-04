import { useQuery } from '@apollo/react-hooks';
import { Box, createMuiTheme, CssBaseline, Fade } from '@material-ui/core';
import { blue, pink } from '@material-ui/core/colors';
import { ThemeProvider } from '@material-ui/styles';
import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Redirect, Route, Switch } from 'react-router-dom';
import { AddProduct } from './components/AddProduct';
import { BottomBar } from './components/BottomBar';
import { FriendList } from './components/FriendList';
import { MobileMenu } from './components/MobileMenu';
import { NavigationBar } from './components/NavigationBar/';
import { Notifications } from './components/Notification';
import { THEME } from './graphql';
import { Account } from './scenes/Account';
import { Activity } from './scenes/Activity';
import { Discover } from './scenes/Discover';
import { LogIn } from './scenes/LogIn';
import { Product } from './scenes/Product';
import { ProductList } from './scenes/ProductList';
import { Profile } from './scenes/Profile';
import { SignUp } from './scenes/SignUp';
import { UserList } from './scenes/UserList';

const darkTheme = createMuiTheme({
    palette: {
        type: 'dark',
        primary: blue,
        secondary: pink,
    },
});

const whiteTheme = createMuiTheme({
    palette: {
        primary: blue,
        secondary: pink,
    },
});

const App = (): JSX.Element => {
    const [token, setToken] = useState();
    const [id, setId] = useState();
    const themeSwitcher = useQuery(THEME);
    const theme = themeSwitcher.data.theme ? 1 : 0;
    const themes = [darkTheme, whiteTheme];

    useEffect((): void => {
        const token = localStorage.getItem('token');
        const userId = localStorage.getItem('id');
        if (token) {
            setToken(token);
            setId(userId);
        }
    }, [token]);

    return (
        <div>
            <ThemeProvider theme={themes[theme]}>
                <CssBaseline />
                <Router>
                    <Notifications />
                    {!token ? (
                        <Switch>
                            <Route exact path="/" render={(): JSX.Element => <LogIn setToken={setToken} />} />
                            <Route exact path="/signup" render={(): JSX.Element => <SignUp setToken={setToken} />} />
                            <Route render={(): JSX.Element => <LogIn setToken={setToken} />} />
                        </Switch>
                    ) : (
                        <div style={{ paddingTop: 70 }}>
                            <NavigationBar setToken={setToken} />
                            <Fade timeout={300}>
                                <Switch>
                                    <Route exact path="/products" component={ProductList} />
                                    <Route exact path="/discover" component={Discover} />
                                    <Route exact path="/users" component={UserList} />
                                    <Route exact path="/activity" component={Activity} />
                                    <Route exact path="/product/new" component={AddProduct} />
                                    <Route exact path="/friends" render={(): JSX.Element => <FriendList id={id} />} />
                                    <Route
                                        exact
                                        path="/menu"
                                        render={(): JSX.Element => <MobileMenu setToken={setToken} />}
                                    />
                                    <Route
                                        exact
                                        path="/account"
                                        render={(): JSX.Element => <Account setToken={setToken} />}
                                    />
                                    <Redirect from="/profile" to={`/user/${id}`} />
                                    <Route
                                        exact
                                        path="/product/:id"
                                        render={({ match }): JSX.Element => <Product id={match.params.id} />}
                                    />
                                    <Route
                                        exact
                                        path="/user/:id"
                                        render={({ match }): JSX.Element => <Profile id={match.params.id} />}
                                    />
                                    <Redirect from="/" to="/activity" />
                                    <Route component={Activity} />
                                </Switch>
                            </Fade>
                            <Box display={{ xs: 'block', md: 'none' }}>
                                <BottomBar />
                            </Box>
                        </div>
                    )}
                </Router>
            </ThemeProvider>
        </div>
    );
};

export default App;
